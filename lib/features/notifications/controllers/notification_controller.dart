import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../../../routes/app_routes.dart';
import '../models/app_notification.dart';
import '../models/stock_alert.dart';
import '../models/transfer_notification.dart';
import '../services/notification_service.dart';

/// GetX Controller managing notification state, unread counters, periodic polling,
/// and instant in-app alerts for pending caisse cash requests and system events.
class NotificationController extends GetxController {
  final NotificationService _service = NotificationService();

  final status = ViewStatus.initial.obs;
  final errorMessage = RxnString();

  final systemNotifications = <AppNotification>[].obs;
  final transferNotifications = <TransferNotification>[].obs;
  final stockAlerts = <StockAlert>[].obs;

  Timer? _pollingTimer;
  final Set<int> _knownNotificationIds = {};
  bool _isFirstLoad = true;

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
    loadAll();
    _startPolling();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
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
  Future<void> loadAll() async {
    status.value = ViewStatus.loading;
    errorMessage.value = null;

    try {
      final userId = StorageService.instance.userId;
      final siteId = StorageService.instance.defaultSiteId;

      final results = await Future.wait([
        _service.fetchUnreads(),
        if (userId != null && userId > 0)
          _service.getMissedNotifications(userId)
        else
          Future.value(<TransferNotification>[]),
        _service.fetchStockAlerts(siteId: siteId),
      ]);

      final unreads = results[0] as List<AppNotification>;
      for (final item in unreads) {
        _knownNotificationIds.add(item.id);
      }
      _isFirstLoad = false;

      systemNotifications.assignAll(unreads);
      transferNotifications.assignAll(results[1] as List<TransferNotification>);
      stockAlerts.assignAll(results[2] as List<StockAlert>);

      status.value = ViewStatus.success;
    } catch (e) {
      status.value = ViewStatus.error;
      errorMessage.value = 'Impossible de charger les notifications: $e';
    }
  }

  /// Silent background update that triggers notifications for newly arrived items.
  Future<void> pollForUpdates() async {
    try {
      final unreads = await _service.fetchUnreads();
      final newItems = <AppNotification>[];

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
        return;
      }

      // If new notifications arrived and current user is an Admin, notify in real-time
      if (StorageService.instance.isAdmin && newItems.isNotEmpty) {
        for (final item in newItems) {
          _notifyAdminInRealTime(item);
        }
      }
    } catch (_) {
      // Non-blocking silent error during polling
    }
  }

  /// Displays an in-app heads-up banner to the administrator for real-time notification
  void _notifyAdminInRealTime(AppNotification item) {
    final isCaisse = item.isCaisseRequest;
    final chantierId = item.chantierIdFromAction;

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
      mainButton: (isCaisse && chantierId != null)
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
      } else {
        systemNotifications.removeWhere((n) => n.id == id);
      }
    } catch (_) {}
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
