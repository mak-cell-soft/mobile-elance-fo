import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:woodapp/core/config/env.dart';
import 'package:woodapp/core/storage/storage_service.dart';
import 'package:woodapp/features/auth/controllers/auth_controller.dart';
import 'package:woodapp/features/notifications/services/fcm_service.dart';
import 'package:woodapp/features/notifications/services/notification_service.dart';

class MockNotificationService extends NotificationService {
  bool registerCalled = false;
  bool unregisterCalled = false;
  String? registeredToken;
  String? unregisteredToken;
  String? registeredPlatform;
  String? registeredAppVersion;
  bool registerSuccess = true;
  bool unregisterSuccess = true;

  @override
  Future<bool> registerDeviceToken({
    required String token,
    String platform = 'android',
    String? appVersion,
  }) async {
    registerCalled = true;
    registeredToken = token;
    registeredPlatform = platform;
    registeredAppVersion = appVersion;
    return registerSuccess;
  }

  @override
  Future<bool> unregisterDeviceToken({required String token}) async {
    unregisterCalled = true;
    unregisteredToken = token;
    return unregisterSuccess;
  }
}

String _createMockJwt({required String userId, required String tenantSlug}) {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'nameid': userId,
            'tenant_slug': tenantSlug,
            'role': 'Admin',
          }),
        ),
      )
      .replaceAll('=', '');
  return '$header.$payload.signature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('fcm_test_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return tempDir.path;
        });
    await StorageService.ensureInitialized();
  });

  setUp(() async {
    Get.testMode = true;
    EnvConfig.init(Flavor.development);
    await StorageService.instance.clearSession();
    await StorageService.instance.clearTenant();
    FcmService.instance.resetForTesting();
  });

  tearDown(() async {
    await StorageService.instance.clearSession();
    await StorageService.instance.clearTenant();
    FcmService.instance.resetForTesting();
    Get.reset();
  });

  group('FcmService Initialization & Flavor Guard Tests', () {
    test('EnvConfig.supportsFcm policy reflects supported flavors correctly', () {
      EnvConfig.init(Flavor.development);
      expect(EnvConfig.supportsFcm, isTrue);

      EnvConfig.init(Flavor.production);
      expect(EnvConfig.supportsFcm, isTrue);

      EnvConfig.init(Flavor.preprod);
      expect(EnvConfig.supportsFcm, isFalse);
    });

    test('Initializes successfully under Flavor.development', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'test_fcm_token_123',
        tokenRefreshStreamProvider: () => const Stream.empty(),
      );

      await FcmService.instance.init();

      expect(FcmService.instance.isInitialized, isTrue);
      expect(FcmService.instance.currentToken, equals('test_fcm_token_123'));
    });

    test('Initializes successfully under Flavor.production', () async {
      EnvConfig.init(Flavor.production);
      final mockNotif = MockNotificationService();

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'prod_fcm_token_456',
        tokenRefreshStreamProvider: () => const Stream.empty(),
      );

      await FcmService.instance.init();

      expect(FcmService.instance.isInitialized, isTrue);
      expect(FcmService.instance.currentToken, equals('prod_fcm_token_456'));
    });

    test('Skips initialization under unsupported Flavor.preprod', () async {
      EnvConfig.init(Flavor.preprod);
      final mockNotif = MockNotificationService();

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'should_not_be_used',
      );

      await FcmService.instance.init();

      expect(FcmService.instance.isInitialized, isFalse);
      expect(FcmService.instance.currentToken, isNull);
    });

    test('Safely disables FCM when Firebase Core is uninitialized without test hooks', () async {
      EnvConfig.init(Flavor.production);
      // Reset to clear any test hooks so it checks Firebase.apps
      FcmService.instance.resetForTesting();

      // Firebase.apps is empty in unit test environment
      await FcmService.instance.init();

      expect(FcmService.instance.isInitialized, isFalse);
      expect(FcmService.instance.currentToken, isNull);
    });

    test('Handles missing/empty token gracefully without throwing', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => null,
      );

      await FcmService.instance.init();

      expect(FcmService.instance.isInitialized, isTrue);
      expect(FcmService.instance.currentToken, isNull);
    });
  });

  group('Token Registration Tests', () {
    test('Registration fails if user is not authenticated', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'token_unauth',
      );
      await FcmService.instance.init();

      final result = await FcmService.instance.registerCurrentToken();

      expect(result, isFalse);
      expect(mockNotif.registerCalled, isFalse);
    });

    test('Registration fails if tenant context is missing', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'socofeb'),
      );
      // No tenantSlug in storage
      await StorageService.instance.clearTenant();

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'token_no_tenant',
      );
      await FcmService.instance.init();

      final result = await FcmService.instance.registerCurrentToken();

      expect(result, isFalse);
      expect(mockNotif.registerCalled, isFalse);
    });

    test('Registration succeeds when token, auth, and tenant are available', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '10', tenantSlug: 'socofeb'),
      );
      await StorageService.instance.saveTenantSlug('socofeb');

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'token_valid_socofeb',
      );
      await FcmService.instance.init();

      final result = await FcmService.instance.registerCurrentToken();

      expect(result, isTrue);
      expect(mockNotif.registerCalled, isTrue);
      expect(mockNotif.registeredToken, equals('token_valid_socofeb'));
      expect(mockNotif.registeredPlatform, equals('android'));
    });

    test('Registration succeeds under Flavor.production when token, auth, and tenant are available', () async {
      EnvConfig.init(Flavor.production);
      final mockNotif = MockNotificationService();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '20', tenantSlug: 'socofeb'),
      );
      await StorageService.instance.saveTenantSlug('socofeb');

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'token_prod_socofeb',
      );
      await FcmService.instance.init();

      final result = await FcmService.instance.registerCurrentToken();

      expect(result, isTrue);
      expect(mockNotif.registerCalled, isTrue);
      expect(mockNotif.registeredToken, equals('token_prod_socofeb'));
      expect(mockNotif.registeredPlatform, equals('android'));
    });

    test('Registration is blocked under unsupported Flavor.preprod', () async {
      EnvConfig.init(Flavor.preprod);
      final mockNotif = MockNotificationService();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '30', tenantSlug: 'socofeb'),
      );
      await StorageService.instance.saveTenantSlug('socofeb');

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'token_preprod',
      );
      await FcmService.instance.init();

      final result = await FcmService.instance.registerCurrentToken();

      expect(result, isFalse);
      expect(mockNotif.registerCalled, isFalse);
    });

    test('Token refresh stream updates currentToken and triggers re-registration', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();
      final streamController = StreamController<String>();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '10', tenantSlug: 'socofeb'),
      );
      await StorageService.instance.saveTenantSlug('socofeb');

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'initial_token',
        tokenRefreshStreamProvider: () => streamController.stream,
      );
      await FcmService.instance.init();

      expect(FcmService.instance.currentToken, equals('initial_token'));

      // Emit new token from refresh stream
      streamController.add('refreshed_new_token');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(FcmService.instance.currentToken, equals('refreshed_new_token'));
      expect(mockNotif.registerCalled, isTrue);
      expect(mockNotif.registeredToken, equals('refreshed_new_token'));

      await streamController.close();
    });
  });

  group('Token Unregistration and Logout Ordering Tests', () {
    test('Unregister sends cached token to backend', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'token_to_unregister',
      );
      await FcmService.instance.init();

      final result = await FcmService.instance.unregisterCurrentToken();

      expect(result, isTrue);
      expect(mockNotif.unregisterCalled, isTrue);
      expect(mockNotif.unregisteredToken, equals('token_to_unregister'));
    });

    test('AuthController logout attempts unregister before wiping session', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '10', tenantSlug: 'socofeb'),
      );
      await StorageService.instance.saveTenantSlug('socofeb');

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'logout_token',
      );
      await FcmService.instance.init();

      final authController = AuthController(enableRemoteSync: false);

      // Verify session exists before logout
      expect(StorageService.instance.isLoggedIn, isTrue);

      await authController.logout();

      // Unregister must have been called
      expect(mockNotif.unregisterCalled, isTrue);
      expect(mockNotif.unregisteredToken, equals('logout_token'));

      // Session must be cleared after logout
      expect(StorageService.instance.isLoggedIn, isFalse);
      expect(StorageService.instance.token, isNull);
    });

    test('AuthController logout attempts unregister under Flavor.production', () async {
      EnvConfig.init(Flavor.production);
      final mockNotif = MockNotificationService();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '20', tenantSlug: 'socofeb'),
      );
      await StorageService.instance.saveTenantSlug('socofeb');

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'logout_prod_token',
      );
      await FcmService.instance.init();

      final authController = AuthController(enableRemoteSync: false);

      expect(StorageService.instance.isLoggedIn, isTrue);

      await authController.logout();

      expect(mockNotif.unregisterCalled, isTrue);
      expect(mockNotif.unregisteredToken, equals('logout_prod_token'));
      expect(StorageService.instance.isLoggedIn, isFalse);
    });

    test('AuthController logout skips unregister under unsupported Flavor.preprod', () async {
      EnvConfig.init(Flavor.preprod);
      final mockNotif = MockNotificationService();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '30', tenantSlug: 'socofeb'),
      );
      await StorageService.instance.saveTenantSlug('socofeb');

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'logout_preprod_token',
      );
      await FcmService.instance.init();

      final authController = AuthController(enableRemoteSync: false);

      expect(StorageService.instance.isLoggedIn, isTrue);

      await authController.logout();

      expect(mockNotif.unregisterCalled, isFalse);
      expect(StorageService.instance.isLoggedIn, isFalse);
    });

    test('Failed unregister does not prevent local session from clearing', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();
      mockNotif.unregisterSuccess = false; // Simulating backend 404 or network timeout

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '10', tenantSlug: 'socofeb'),
      );
      await StorageService.instance.saveTenantSlug('socofeb');

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'failing_token',
      );
      await FcmService.instance.init();

      final authController = AuthController(enableRemoteSync: false);

      await authController.logout();

      // Session is still successfully cleared despite backend unregister failure
      expect(StorageService.instance.isLoggedIn, isFalse);
      expect(StorageService.instance.token, isNull);
    });
  });

  group('Foreground Message Listener Tests', () {
    test('Matching tenant is accepted and dispatches notification', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();
      final streamController = StreamController<RemoteMessage>();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      int? receivedNotificationId;
      int callbackCount = 0;

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'test_token',
        foregroundMessageStreamProvider: () => streamController.stream,
        onForegroundNotification: ({notificationId, rawMessage}) {
          callbackCount++;
          receivedNotificationId = notificationId;
        },
      );
      await FcmService.instance.init();

      // Emit foreground message with valid matching tenant
      streamController.add(RemoteMessage(
        data: {
          'notificationId': '42',
          'tenantSlug': 'development',
          'type': '1',
          'priority': '2',
        },
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(callbackCount, equals(1));
      expect(receivedNotificationId, equals(42));

      await streamController.close();
    });

    test('Case-insensitive and surrounding whitespace tenant matching are accepted', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();
      final streamController = StreamController<RemoteMessage>();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      int callbackCount = 0;

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'test_token',
        foregroundMessageStreamProvider: () => streamController.stream,
        onForegroundNotification: ({notificationId, rawMessage}) {
          callbackCount++;
        },
      );
      await FcmService.instance.init();

      // 1. Uppercase with whitespace in payload
      streamController.add(RemoteMessage(
        data: {'notificationId': '1', 'tenantSlug': '  DEVELOPMENT  '},
      ));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callbackCount, equals(1));

      // 2. Active tenant has whitespace, payload has mixed case
      await StorageService.instance.saveTenantSlug('  development  ');
      streamController.add(RemoteMessage(
        data: {'notificationId': '2', 'tenantSlug': 'Development'},
      ));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callbackCount, equals(2));

      await streamController.close();
    });

    test('Different tenant is rejected', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();
      final streamController = StreamController<RemoteMessage>();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      int callbackCount = 0;

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'test_token',
        foregroundMessageStreamProvider: () => streamController.stream,
        onForegroundNotification: ({notificationId, rawMessage}) {
          callbackCount++;
        },
      );
      await FcmService.instance.init();

      // Emit message targeted to a different tenant
      streamController.add(RemoteMessage(
        data: {'notificationId': '7', 'tenantSlug': 'socofeb'},
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(callbackCount, equals(0));

      await streamController.close();
    });

    test('Missing, null, empty, or whitespace-only tenantSlug in payload is rejected', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();
      final streamController = StreamController<RemoteMessage>();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      int callbackCount = 0;

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'test_token',
        foregroundMessageStreamProvider: () => streamController.stream,
        onForegroundNotification: ({notificationId, rawMessage}) {
          callbackCount++;
        },
      );
      await FcmService.instance.init();

      // 1. Missing tenantSlug key
      streamController.add(RemoteMessage(data: {'notificationId': '10'}));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callbackCount, equals(0));

      // 2. Null tenantSlug
      streamController.add(RemoteMessage(data: {'notificationId': '11', 'tenantSlug': null}));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callbackCount, equals(0));

      // 3. Empty string tenantSlug
      streamController.add(RemoteMessage(data: {'notificationId': '12', 'tenantSlug': ''}));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callbackCount, equals(0));

      // 4. Whitespace-only tenantSlug
      streamController.add(RemoteMessage(data: {'notificationId': '13', 'tenantSlug': '   '}));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callbackCount, equals(0));

      // 5. Completely empty map
      streamController.add(RemoteMessage(data: {}));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callbackCount, equals(0));

      await streamController.close();
    });

    test('Non-string tenant value in payload is rejected safely without throwing', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();
      final streamController = StreamController<RemoteMessage>();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      int callbackCount = 0;

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'test_token',
        foregroundMessageStreamProvider: () => streamController.stream,
        onForegroundNotification: ({notificationId, rawMessage}) {
          callbackCount++;
        },
      );
      await FcmService.instance.init();

      // Integer tenantSlug
      streamController.add(RemoteMessage(data: {'tenantSlug': 12345}));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callbackCount, equals(0));

      // Boolean tenantSlug
      streamController.add(RemoteMessage(data: {'tenantSlug': true}));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callbackCount, equals(0));

      // Map tenantSlug
      streamController.add(RemoteMessage(data: {'tenantSlug': {'nested': 'val'}}));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callbackCount, equals(0));

      // List tenantSlug
      streamController.add(RemoteMessage(data: {'tenantSlug': ['development']}));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callbackCount, equals(0));

      await streamController.close();
    });

    test('Null, empty, or whitespace-only active tenant in session is rejected', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();
      final streamController = StreamController<RemoteMessage>();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development'),
      );

      int callbackCount = 0;

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'test_token',
        foregroundMessageStreamProvider: () => streamController.stream,
        onForegroundNotification: ({notificationId, rawMessage}) {
          callbackCount++;
        },
      );
      await FcmService.instance.init();

      // 1. Null active tenant
      await StorageService.instance.clearTenant();
      streamController.add(RemoteMessage(data: {'tenantSlug': 'development'}));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callbackCount, equals(0));

      // 2. Empty string active tenant
      await StorageService.instance.saveTenantSlug('');
      streamController.add(RemoteMessage(data: {'tenantSlug': 'development'}));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callbackCount, equals(0));

      // 3. Whitespace-only active tenant
      await StorageService.instance.saveTenantSlug('   ');
      streamController.add(RemoteMessage(data: {'tenantSlug': 'development'}));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callbackCount, equals(0));

      await streamController.close();
    });

    test('Logged-out messages are ignored', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();
      final streamController = StreamController<RemoteMessage>();

      // User is logged out
      await StorageService.instance.clearSession();

      int callbackCount = 0;

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'test_token',
        foregroundMessageStreamProvider: () => streamController.stream,
        onForegroundNotification: ({notificationId, rawMessage}) {
          callbackCount++;
        },
      );
      await FcmService.instance.init();

      streamController.add(RemoteMessage(
        data: {'notificationId': '5', 'tenantSlug': 'development'},
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(callbackCount, equals(0));

      await streamController.close();
    });

    test('Unsupported flavor (preprod) does not initialize the listener', () async {
      EnvConfig.init(Flavor.preprod);
      final mockNotif = MockNotificationService();
      bool streamRequested = false;

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'token',
        foregroundMessageStreamProvider: () {
          streamRequested = true;
          return const Stream.empty();
        },
      );
      await FcmService.instance.init();

      expect(FcmService.instance.isInitialized, isFalse);
      expect(streamRequested, isFalse);
    });

    test('Production flavor initializes the foreground listener and dispatches notification', () async {
      EnvConfig.init(Flavor.production);
      final mockNotif = MockNotificationService();
      final streamController = StreamController<RemoteMessage>();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'socofeb'),
      );
      await StorageService.instance.saveTenantSlug('socofeb');

      int callbackCount = 0;
      int? receivedId;

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'prod_token',
        foregroundMessageStreamProvider: () => streamController.stream,
        onForegroundNotification: ({notificationId, rawMessage}) {
          callbackCount++;
          receivedId = notificationId;
        },
      );
      await FcmService.instance.init();

      expect(FcmService.instance.isInitialized, isTrue);

      streamController.add(RemoteMessage(
        data: {'notificationId': '77', 'tenantSlug': 'socofeb'},
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(callbackCount, equals(1));
      expect(receivedId, equals(77));

      await streamController.close();
    });

    test('Repeated initialization does not create duplicate listeners', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();
      final streamController = StreamController<RemoteMessage>();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      int callbackCount = 0;

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'test_token',
        foregroundMessageStreamProvider: () => streamController.stream,
        onForegroundNotification: ({notificationId, rawMessage}) {
          callbackCount++;
        },
      );
      await FcmService.instance.init();
      // Second init call without reset
      await FcmService.instance.init();

      // Emit message once
      streamController.add(RemoteMessage(
        data: {'notificationId': '99', 'tenantSlug': 'development'},
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(callbackCount, equals(1));

      await streamController.close();
    });

    test('Malformed or non-integer notificationId does not crash the handler when tenant is valid', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();
      final streamController = StreamController<RemoteMessage>();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      int? lastId;
      int callbackCount = 0;

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'test_token',
        foregroundMessageStreamProvider: () => streamController.stream,
        onForegroundNotification: ({notificationId, rawMessage}) {
          callbackCount++;
          lastId = notificationId;
        },
      );
      await FcmService.instance.init();

      // Valid tenant but invalid notificationId string
      streamController.add(RemoteMessage(
        data: {'notificationId': 'invalid_not_an_int', 'tenantSlug': 'development'},
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(callbackCount, equals(1));
      expect(lastId, isNull);

      await streamController.close();
    });

    test('Subscription cleanup works correctly on dispose and reset', () async {
      EnvConfig.init(Flavor.development);
      final mockNotif = MockNotificationService();
      final streamController = StreamController<RemoteMessage>();

      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      int callbackCount = 0;

      FcmService.instance.configureForTesting(
        notificationService: mockNotif,
        tokenRetriever: () async => 'test_token',
        foregroundMessageStreamProvider: () => streamController.stream,
        onForegroundNotification: ({notificationId, rawMessage}) {
          callbackCount++;
        },
      );
      await FcmService.instance.init();

      // Dispose service
      FcmService.instance.dispose();

      expect(FcmService.instance.isInitialized, isFalse);

      // Emitting on stream should not trigger callback after dispose
      streamController.add(RemoteMessage(
        data: {'notificationId': '1', 'tenantSlug': 'development'},
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(callbackCount, equals(0));

      await streamController.close();
    });
  });
}
