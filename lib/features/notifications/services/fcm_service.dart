import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/config/env.dart';
import '../../../core/storage/storage_service.dart';
import '../controllers/notification_controller.dart';
import 'notification_service.dart';

typedef TokenRetriever = Future<String?> Function();
typedef TokenRefreshStreamProvider = Stream<String> Function();
typedef PermissionRequester = Future<NotificationSettings> Function();
typedef ForegroundMessageStreamProvider = Stream<RemoteMessage> Function();
typedef ForegroundNotificationHandler = FutureOr<void> Function({int? notificationId, RemoteMessage? rawMessage});

/// Development-only service managing Firebase Cloud Messaging (FCM) device tokens
/// and foreground message delivery.
///
/// Responsibilities:
/// 1. Requests Android 13+ / iOS notification permission.
/// 2. Retrieves the FCM registration token and listens to token refresh events.
/// 3. Registers the token with the backend device registration API when authenticated.
/// 4. Attempts token unregistration during logout before credentials are wiped.
/// 5. Listens to foreground FCM messages and triggers immediate state refresh.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  NotificationService _notificationService = NotificationService();
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  String? _currentToken;
  bool _isInitialized = false;

  // Optional test hooks for isolated unit testing without platform channels
  TokenRetriever? tokenRetriever;
  TokenRefreshStreamProvider? tokenRefreshStreamProvider;
  PermissionRequester? permissionRequester;
  ForegroundMessageStreamProvider? foregroundMessageStreamProvider;
  ForegroundNotificationHandler? onForegroundNotification;

  String? get currentToken => _currentToken;
  bool get isInitialized => _isInitialized;

  @visibleForTesting
  void configureForTesting({
    required NotificationService notificationService,
    TokenRetriever? tokenRetriever,
    TokenRefreshStreamProvider? tokenRefreshStreamProvider,
    PermissionRequester? permissionRequester,
    ForegroundMessageStreamProvider? foregroundMessageStreamProvider,
    ForegroundNotificationHandler? onForegroundNotification,
  }) {
    _notificationService = notificationService;
    this.tokenRetriever = tokenRetriever;
    this.tokenRefreshStreamProvider = tokenRefreshStreamProvider;
    this.permissionRequester = permissionRequester;
    this.foregroundMessageStreamProvider = foregroundMessageStreamProvider;
    this.onForegroundNotification = onForegroundNotification;
    _isInitialized = false;
  }

  @visibleForTesting
  void resetForTesting() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _messageSub?.cancel();
    _messageSub = null;
    _currentToken = null;
    _isInitialized = false;
    tokenRetriever = null;
    tokenRefreshStreamProvider = null;
    permissionRequester = null;
    foregroundMessageStreamProvider = null;
    onForegroundNotification = null;
    _notificationService = NotificationService();
  }

  /// Initializes the FCM integration for supported flavors.
  /// Safe against crashes; failures are logged without disrupting app startup.
  Future<void> init() async {
    if (!EnvConfig.supportsFcm) {
      debugPrint('[FCM] Skipped: FcmService is only active for supported flavors.');
      return;
    }

    if (_isInitialized) {
      debugPrint('[FCM] Already initialized.');
      return;
    }

    final bool hasTestHooks = tokenRetriever != null ||
        permissionRequester != null ||
        tokenRefreshStreamProvider != null ||
        foregroundMessageStreamProvider != null;

    if (!hasTestHooks && Firebase.apps.isEmpty) {
      debugPrint('[FCM] Skipped: Firebase Core is not initialized.');
      return;
    }

    try {
      // 1. Request notification permission (Android 13+ POST_NOTIFICATIONS)
      if (permissionRequester != null) {
        await permissionRequester!();
      } else if (Firebase.apps.isNotEmpty) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('[FCM] Notification permission status: ${settings.authorizationStatus}');
      }

      // 2. Retrieve initial FCM device token
      if (tokenRetriever != null) {
        _currentToken = await tokenRetriever!();
      } else if (Firebase.apps.isNotEmpty) {
        // ignore: deprecated_member_use
        _currentToken = await FirebaseMessaging.instance.getToken();
      }

      if (_currentToken != null && _currentToken!.isNotEmpty) {
        debugPrint('[FCM] FCM device token retrieved successfully (redacted).');
      } else {
        debugPrint('[FCM] No FCM token returned.');
      }

      // 3. Register single subscription for token refresh
      Stream<String>? refreshStream;
      if (tokenRefreshStreamProvider != null) {
        refreshStream = tokenRefreshStreamProvider!();
      } else if (Firebase.apps.isNotEmpty) {
        // ignore: deprecated_member_use
        refreshStream = FirebaseMessaging.instance.onTokenRefresh;
      }

      if (refreshStream != null) {
        _tokenRefreshSub?.cancel();
        _tokenRefreshSub = refreshStream.listen((newToken) {
          if (newToken.trim().isNotEmpty) {
            _currentToken = newToken.trim();
            debugPrint('[FCM] FCM token refreshed (redacted).');
            if (StorageService.instance.isLoggedIn) {
              registerCurrentToken();
            }
          }
        });
      }

      // 4. Register single subscription for foreground FCM messages
      Stream<RemoteMessage>? messageStream;
      if (foregroundMessageStreamProvider != null) {
        messageStream = foregroundMessageStreamProvider!();
      } else if (Firebase.apps.isNotEmpty) {
        messageStream = FirebaseMessaging.onMessage;
      }

      if (messageStream != null) {
        _messageSub?.cancel();
        _messageSub = messageStream.listen((message) {
          _handleForegroundMessage(message);
        });
      }

      _isInitialized = true;

      // 5. If user is already authenticated upon startup, register immediately
      if (StorageService.instance.isLoggedIn) {
        await registerCurrentToken();
      }
    } catch (e) {
      debugPrint('[FCM] Gracefully handled initialization error: $e');
    }
  }

  /// Processes an incoming FCM message received while the app is active in foreground.
  /// Validates session and tenant context strictly before triggering state refresh.
  void _handleForegroundMessage(RemoteMessage message) {
    if (!EnvConfig.supportsFcm) {
      return;
    }

    // 1. Authenticated session check
    if (!StorageService.instance.isLoggedIn) {
      debugPrint('[FCM] Discarded foreground message: User is not authenticated.');
      return;
    }

    // 2. Active session tenant check
    final activeTenant = StorageService.instance.tenantSlug;
    if (activeTenant == null || activeTenant.trim().isEmpty) {
      debugPrint('[FCM] Discarded foreground message: Active tenant context is missing.');
      return;
    }

    // 3. Strict payload tenant check (must exist, must be String, non-empty after trim)
    final rawPayloadTenant = message.data['tenantSlug'];
    if (rawPayloadTenant is! String) {
      debugPrint('[FCM] Discarded foreground message: Payload tenant is missing or not a string.');
      return;
    }

    final normalizedPayloadTenant = rawPayloadTenant.trim().toLowerCase();
    final normalizedActiveTenant = activeTenant.trim().toLowerCase();

    if (normalizedPayloadTenant.isEmpty || normalizedPayloadTenant != normalizedActiveTenant) {
      debugPrint('[FCM] Discarded foreground message: Tenant mismatch or empty.');
      return;
    }

    // 4. Extract optional notification ID safely
    int? notificationId;
    final rawId = message.data['notificationId'];
    if (rawId != null) {
      notificationId = int.tryParse(rawId.toString());
    }

    debugPrint('[FCM] Foreground notification event received (notificationId: $notificationId).');

    if (onForegroundNotification != null) {
      onForegroundNotification!(notificationId: notificationId, rawMessage: message);
    } else {
      try {
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().onForegroundMessage(notificationId: notificationId);
        }
      } catch (e) {
        debugPrint('[FCM] Failed to dispatch foreground message to controller: $e');
      }
    }
  }

  /// Registers the current device token with the backend if an authenticated
  /// session and valid tenant context exist.
  Future<bool> registerCurrentToken() async {
    if (!EnvConfig.supportsFcm) {
      return false;
    }

    final token = _currentToken;
    if (token == null || token.isEmpty) {
      debugPrint('[FCM] Cannot register: No FCM token cached.');
      return false;
    }

    if (!StorageService.instance.isLoggedIn) {
      debugPrint('[FCM] Cannot register: User is not authenticated.');
      return false;
    }

    final tenantSlug = StorageService.instance.tenantSlug;
    if (tenantSlug == null || tenantSlug.isEmpty) {
      debugPrint('[FCM] Cannot register: Tenant context is missing.');
      return false;
    }

    debugPrint('[FCM] Registering device token for tenant: $tenantSlug (token redacted)');
    return await _notificationService.registerDeviceToken(
      token: token,
      platform: 'android',
      appVersion: '1.0.0+1',
    );
  }

  /// Attempts to unregister the current device token from the backend before
  /// the active session credentials are wiped during logout.
  Future<bool> unregisterCurrentToken() async {
    if (!EnvConfig.supportsFcm) {
      return false;
    }

    final token = _currentToken;
    if (token == null || token.isEmpty) {
      debugPrint('[FCM] Cannot unregister: No FCM token cached.');
      return false;
    }

    debugPrint('[FCM] Unregistering device token from server (token redacted)');
    try {
      return await _notificationService.unregisterDeviceToken(token: token);
    } catch (e) {
      debugPrint('[FCM] Non-fatal error during unregisterCurrentToken: $e');
      return false;
    }
  }

  /// Cleans up active subscriptions.
  void dispose() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _messageSub?.cancel();
    _messageSub = null;
    _isInitialized = false;
  }
}
