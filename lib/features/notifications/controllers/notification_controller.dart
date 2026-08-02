import 'package:get/get.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../models/app_notification.dart';
import '../models/stock_alert.dart';
import '../models/transfer_notification.dart';
import '../services/notification_service.dart';

/// GetX Controller managing notification state, unread counters, and API actions.
class NotificationController extends GetxController {
  final NotificationService _service = NotificationService();

  final status = ViewStatus.initial.obs;
  final errorMessage = RxnString();

  final systemNotifications = <AppNotification>[].obs;
  final transferNotifications = <TransferNotification>[].obs;
  final stockAlerts = <StockAlert>[].obs;

  /// Total count of unread items across all notification categories.
  int get unreadCount =>
      systemNotifications.where((n) => !n.isRead).length +
      transferNotifications.length +
      stockAlerts.length;

  @override
  void onInit() {
    super.onInit();
    loadAll();
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

      systemNotifications.assignAll(results[0] as List<AppNotification>);
      transferNotifications.assignAll(results[1] as List<TransferNotification>);
      stockAlerts.assignAll(results[2] as List<StockAlert>);

      status.value = ViewStatus.success;
    } catch (e) {
      status.value = ViewStatus.error;
      errorMessage.value = 'Impossible de charger les notifications: $e';
    }
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
