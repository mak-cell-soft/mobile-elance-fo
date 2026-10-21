import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/env.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../../../routes/app_routes.dart';
import '../models/app_notification.dart';
import '../models/stock_alert.dart';
import '../models/transfer_notification.dart';
import '../models/transferred_article_item.dart';
import '../services/fcm_service.dart';
import '../services/notification_service.dart';

/// GetX Controller managing notification state, unread counters, periodic polling,
/// and instant in-app alerts for pending caisse cash requests and system events.
class NotificationController extends GetxController with WidgetsBindingObserver {
  final NotificationService _service;
  final bool _enablePolling;

  NotificationController({
    NotificationService? service,
    bool enablePolling = true,
  })  : _service = service ?? NotificationService(),
        _enablePolling = enablePolling;

  final status = ViewStatus.initial.obs;
  final errorMessage = RxnString();

  final systemNotifications = <AppNotification>[].obs;
  final transferNotifications = <TransferNotification>[].obs;
  final stockAlerts = <StockAlert>[].obs;

  /// Cached transferred article lines per transfer ID to prevent duplicate requests or repeated fetches.
  final transferDetails = <int, List<TransferredArticleItem>>{}.obs;

  /// Loading state per transfer card expansion.
  final loadingTransferDetails = <int, bool>{}.obs;

  /// Error message per transfer card detail loading failure.
  final errorTransferDetails = <int, String?>{}.obs;

  /// Set of expanded transfer card IDs.
  final expandedTransferIds = <int>{}.obs;

  Timer? _pollingTimer;
  final Set<int> _knownNotificationIds = {};
  bool _isFirstLoad = true;

  // Concurrency and race condition guards for system polling
  bool _isPolling = false;
  bool _hasPendingRefresh = false;
  int _pollSequence = 0;

  // Concurrency guards for transfer notifications
  bool _isRefreshingTransfers = false;
  bool _hasPendingTransferRefresh = false;

  @visibleForTesting
  Function(AppNotification item)? onNotificationFeedbackForTesting;

  /// Total count of unread items across all notification categories.
  int get unreadCount =>
      systemNotifications.where((n) => !n.isRead).length +
      transferNotifications.length +
      stockAlerts.length;

  /// Unread count specifically for caisse/treasury cash requests.
  int get unreadCaisseCount =>
      systemNotifications.where((n) => !n.isRead && n.isCaisseRequest).length;

  @override
  void onInit() {
    super.onInit();
    // Register lifecycle observer to refresh state on app resume
    WidgetsBinding.instance.addObserver(this);
    loadAll();
    if (_enablePolling) {
      _startPolling();
    }
    _registerFcmForegroundHandler();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    if (EnvConfig.supportsFcm) {
      if (FcmService.instance.onForegroundNotification != null) {
        FcmService.instance.onForegroundNotification = null;
      }
    }
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // On app resume, refresh notification state if user is authenticated
    if (state == AppLifecycleState.resumed && StorageService.instance.isLoggedIn) {
      onAppResumed();
    }
  }

  /// Refreshes relevant notification data when app resumes from background.
  /// Guarded against redundant concurrent requests.
  Future<void> onAppResumed() async {
    await Future.wait([
      pollForUpdates(),
      refreshTransfers(),
    ]);
  }

  /// Called whenever the notifications screen or its Transfers tab is opened or revisited.
  /// Refreshes transfers and unread notifications without redundant concurrent calls.
  Future<void> onScreenOpened() async {
    await Future.wait([
      refreshTransfers(),
      pollForUpdates(),
    ]);
  }

  /// Refreshes inter-site transfer notifications for the current authenticated user.
  /// Uses existing GET /stock/notifications/missed endpoint.
  /// Guarded against concurrent overlapping requests.
  Future<void> refreshTransfers() async {
    if (_isRefreshingTransfers) {
      _hasPendingTransferRefresh = true;
      return;
    }

    _isRefreshingTransfers = true;

    try {
      final userId = StorageService.instance.userId;
      if (userId != null && userId > 0) {
        final missed = await _service.getMissedNotifications(userId);
        transferNotifications.assignAll(missed);
      } else {
        transferNotifications.clear();
      }
    } catch (e) {
      debugPrint('[NotificationController] Failed to refresh transfers: $e');
    } finally {
      _isRefreshingTransfers = false;
      if (_hasPendingTransferRefresh) {
        _hasPendingTransferRefresh = false;
        refreshTransfers();
      }
    }
  }

  /// Automatically registers this controller as the foreground FCM listener if in a supported flavor.
  void _registerFcmForegroundHandler() {
    if (EnvConfig.supportsFcm) {
      FcmService.instance.onForegroundNotification = ({notificationId, rawMessage}) {
        onForegroundMessage(notificationId: notificationId, rawMessage: rawMessage);
      };
    }
  }

  /// Handles a foreground notification event received via FCM.
  /// Triggers an immediate authoritative state refresh without waiting for polling.
  /// Identifies transfer events from raw payload or authoritative unreads API.
  Future<void> onForegroundMessage({int? notificationId, RemoteMessage? rawMessage}) async {
    // 1. Direct inspection: check relatedEntityType in raw payload if present
    final rawType = (rawMessage?.data['relatedEntityType'] ?? rawMessage?.data['entityType'])
        ?.toString()
        .toLowerCase();
    bool isTransferEvent = rawType == 'stocktransfer';

    // 2. Poll for updates to fetch authoritative AppNotification list from API
    final newItems = await pollForUpdates();

    // 3. Fallback inspection if not explicitly marked in raw FCM payload:
    //    Find target notification by notificationId in systemNotifications
    if (!isTransferEvent && notificationId != null) {
      final match = systemNotifications.firstWhereOrNull((n) => n.id == notificationId);
      if (match != null && match.isTransferNotification) {
        isTransferEvent = true;
      }
    }

    // 4. Also check newly arrived items from this polling round
    if (!isTransferEvent && newItems.any((n) => n.isTransferNotification)) {
      isTransferEvent = true;
    }

    // 5. If this event is identified as a merchandise transfer, refresh transfers list
    if (isTransferEvent) {
      await refreshTransfers();
    }
  }

  /// Starts background polling every 30 seconds while user is logged in.
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (StorageService.instance.isLoggedIn) {
        pollForUpdates();
      }
    });
  }

  /// Loads system notifications, missed inter-site transfers, and stock alerts.
  /// Individual endpoints are isolated so that a failure in one does not abort others.
  Future<void> loadAll() async {
    status.value = ViewStatus.loading;
    errorMessage.value = null;

    final userId = StorageService.instance.userId;
    final siteId = StorageService.instance.defaultSiteId;

    final errors = <String>[];
    List<AppNotification>? unreads;
    List<TransferNotification>? transfers;
    List<StockAlert>? alerts;

    await Future.wait([
      _service.fetchUnreads().then((val) {
        unreads = val;
      }).catchError((e) {
        debugPrint('[NotificationController] Failed to fetch unreads: $e');
        errors.add('notifications ($e)');
      }),
      ((userId != null && userId > 0)
              ? _service.getMissedNotifications(userId)
              : Future.value(<TransferNotification>[]))
          .then((val) {
        transfers = val;
      }).catchError((e) {
        debugPrint('[NotificationController] Failed to fetch transfers: $e');
        errors.add('transferts ($e)');
      }),
      _service.fetchStockAlerts(siteId: siteId).then((val) {
        alerts = val;
      }).catchError((e) {
        debugPrint('[NotificationController] Failed to fetch stock alerts: $e');
        errors.add('alertes de stock ($e)');
      }),
    ]);

    if (unreads != null) {
      for (final item in unreads!) {
        _knownNotificationIds.add(item.id);
      }
      systemNotifications.assignAll(unreads!);
    }
    if (transfers != null) {
      transferNotifications.assignAll(transfers!);
    }
    if (alerts != null) {
      stockAlerts.assignAll(alerts!);
    }

    _isFirstLoad = false;

    if (unreads == null && transfers == null && alerts == null) {
      status.value = ViewStatus.error;
      errorMessage.value = 'Impossible de charger les notifications: ${errors.join(', ')}';
    } else {
      status.value = ViewStatus.success;
      if (errors.isNotEmpty) {
        errorMessage.value = 'Certaines données n\'ont pas pu être chargées: ${errors.join(', ')}';
      }
    }
  }

  /// Silent background update or push-triggered refresh that fetches unreads
  /// and triggers heads-up feedback for newly arrived items.
  Future<List<AppNotification>> pollForUpdates() async {
    if (_isPolling) {
      _hasPendingRefresh = true;
      return [];
    }

    _isPolling = true;
    final currentSeq = ++_pollSequence;
    final newItems = <AppNotification>[];

    try {
      final unreads = await _service.fetchUnreads();

      // Discard older responses if a newer poll sequence was initiated
      if (currentSeq < _pollSequence) {
        return [];
      }

      for (final item in unreads) {
        if (!_knownNotificationIds.contains(item.id)) {
          _knownNotificationIds.add(item.id);
          if (!_isFirstLoad) {
            newItems.add(item);
          }
        }
      }

      systemNotifications.assignAll(unreads);

      if (_isFirstLoad) {
        _isFirstLoad = false;
        return [];
      }

      // If new notifications arrived, display heads-up feedback
      if (newItems.isNotEmpty) {
        for (final item in newItems) {
          if (StorageService.instance.isAdmin) {
            _notifyAdminInRealTime(item);
          } else {
            _notifyUserInRealTime(item);
          }
        }
      }
      return newItems;
    } catch (_) {
      // Non-blocking silent error during polling
      return [];
    } finally {
      _isPolling = false;
      if (_hasPendingRefresh) {
        _hasPendingRefresh = false;
        // Trigger subsequent refresh to capture events that arrived while polling was active
        pollForUpdates();
      }
    }
  }

  /// Displays an in-app heads-up banner to standard users for real-time notification
  void _notifyUserInRealTime(AppNotification item) {
    if (onNotificationFeedbackForTesting != null) {
      onNotificationFeedbackForTesting!(item);
    }
    if (Get.overlayContext == null) return;

    Get.snackbar(
      item.title,
      item.message,
      icon: const Icon(
        Icons.notifications_active_rounded,
        color: Colors.white,
        size: 24,
      ),
      backgroundColor: const Color(0xFF1E3A8A),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 4),
    );
  }

  /// Displays an in-app heads-up banner to the administrator for real-time notification
  void _notifyAdminInRealTime(AppNotification item) {
    if (onNotificationFeedbackForTesting != null) {
      onNotificationFeedbackForTesting!(item);
    }
    if (Get.overlayContext == null) return;

    final isCaisse = item.isCaisseRequest;
    final chantierId = item.chantierIdFromAction;
    final canAccessChantier = StorageService.instance.hasChantierModule;

    Get.snackbar(
      item.title,
      item.message,
      icon: Icon(
        isCaisse ? Icons.account_balance_wallet_rounded : Icons.notifications_active_rounded,
        color: Colors.white,
        size: 24,
      ),
      backgroundColor: isCaisse ? const Color(0xFFD97706) : const Color(0xFF1E3A8A),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 6),
      mainButton: (isCaisse && chantierId != null && canAccessChantier)
          ? TextButton(
              onPressed: () {
                if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
                navigateToChantierCaisse(chantierId);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text(
                'Examiner',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          : null,
    );
  }

  /// Navigates directly to a chantier's Caisse tab (tab index 2)
  void navigateToChantierCaisse(int chantierId) {
    if (!StorageService.instance.hasChantierModule) {
      Get.snackbar(
        'Accès non disponible',
        'Le module Chantiers n\'est pas activé pour votre entreprise.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.toNamed(
      AppRoutes.chantierDetail,
      arguments: {'id': chantierId, 'tab': 2},
    );
  }

  /// Marks a specific system notification as read.
  Future<void> markAsRead(int id) async {
    try {
      await _service.markAsRead(id);
      final index = systemNotifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        systemNotifications[index] =
            systemNotifications[index].copyWith(isRead: true);
        systemNotifications.refresh();
      }
    } catch (_) {}
  }

  /// Marks all system notifications as read.
  Future<void> markAllAsRead() async {
    final unreads = systemNotifications.where((n) => !n.isRead).toList();
    for (final item in unreads) {
      await markAsRead(item.id);
    }
  }

  /// Dismisses a notification item.
  Future<void> dismiss(int id, {bool isTransfer = false}) async {
    try {
      await _service.dismissNotification(id);
      if (isTransfer) {
        transferNotifications.removeWhere((t) => t.id == id);
        transferDetails.remove(id);
        loadingTransferDetails.remove(id);
        errorTransferDetails.remove(id);
        expandedTransferIds.remove(id);
      } else {
        systemNotifications.removeWhere((n) => n.id == id);
      }
    } catch (_) {}
  }

  /// Toggles expansion of transferred article line items for a specific transfer card.
  /// Automatically fetches article details if not already loaded or cached.
  void toggleTransferExpanded(TransferNotification transfer) {
    if (expandedTransferIds.contains(transfer.id)) {
      expandedTransferIds.remove(transfer.id);
    } else {
      expandedTransferIds.add(transfer.id);
      if (!transferDetails.containsKey(transfer.id) &&
          (transfer.inlineArticles == null || transfer.inlineArticles!.isEmpty)) {
        loadTransferDetails(transfer);
      } else if (transfer.inlineArticles != null && transfer.inlineArticles!.isNotEmpty) {
        transferDetails[transfer.id] = transfer.inlineArticles!;
      }
    }
  }

  /// Fetches transferred merchandise lines from GET /stock/transfers/details without duplicate requests.
  Future<void> loadTransferDetails(TransferNotification transfer) async {
    final transferId = transfer.id;

    // Check if already in flight
    if (loadingTransferDetails[transferId] == true) return;

    // Check if already loaded and non-empty
    if (transferDetails.containsKey(transferId) && transferDetails[transferId]!.isNotEmpty) {
      return;
    }

    loadingTransferDetails[transferId] = true;
    errorTransferDetails[transferId] = null;

    try {
      final details = await _service.fetchTransferDetails(
        originDoc: transfer.exitDocNumber,
        receiptDoc: transfer.receiptDocNumber,
      );
      transferDetails[transferId] = details;

      // If details returned human-readable site names and transfer notification lacked them, enrich the card
      if (details.isNotEmpty) {
        final first = details.first;
        final hasOriginName = first.originSiteName != null && first.originSiteName!.trim().isNotEmpty;
        final hasDestName = first.destinationSiteName != null && first.destinationSiteName!.trim().isNotEmpty;
        if ((hasOriginName && transfer.originSiteName == null) ||
            (hasDestName && transfer.destinationSiteName == null)) {
          final index = transferNotifications.indexWhere((t) => t.id == transferId);
          if (index != -1) {
            transferNotifications[index] = transferNotifications[index].copyWith(
              originSiteName: hasOriginName ? first.originSiteName : null,
              destinationSiteName: hasDestName ? first.destinationSiteName : null,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[NotificationController] Failed to load transfer details #$transferId: $e');
      errorTransferDetails[transferId] = 'Impossible de charger les articles de ce transfert.';
    } finally {
      loadingTransferDetails[transferId] = false;
    }
  }

  /// Triggers backend retry of failed notifications.
  Future<void> retryFailed() async {
    try {
      final msg = await _service.retryFailedNotifications();
      Get.snackbar(
        'Notification Retry',
        msg,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec lors de la tentative de renvoi',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
