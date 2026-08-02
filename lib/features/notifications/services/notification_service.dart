import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/app_notification.dart';
import '../models/stock_alert.dart';
import '../models/transfer_notification.dart';

/// Service layer communicating with backend notification endpoints.
/// Directly mirrors `notification.service.ts` from `elance-app.ui`.
class NotificationService {
  final Dio _dio = ApiClient.instance.dio;

  /// Fetches unread system notifications for the current authenticated user (`GET /notifications/unreads`).
  Future<List<AppNotification>> fetchUnreads() async {
    final response = await _dio.get('/notifications/unreads');
    final data = response.data;
    if (data is List) {
      return data
          .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Marks a specific system notification as read (`PUT /notifications/{id}/read`).
  Future<void> markAsRead(int id) async {
    await _dio.put('/notifications/$id/read');
  }

  /// Dismisses/deletes a system or transfer notification (`DELETE /notifications/{id}`).
  Future<void> dismissNotification(int id) async {
    await _dio.delete('/notifications/$id');
  }

  /// Fetches pending/missed inter-site transfer notifications (`GET /stock/notifications/missed`).
  Future<List<TransferNotification>> getMissedNotifications(int userId) async {
    final response = await _dio.get(
      '/stock/notifications/missed',
      queryParameters: {'userId': userId},
    );
    final data = response.data;
    if (data is List) {
      final List<TransferNotification> list = [];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          try {
            list.add(TransferNotification.fromPendingJson(item));
          } catch (_) {}
        }
      }
      return list;
    }
    return [];
  }

  /// Triggers background retry of failed notification deliveries (`POST /notifications/retry-failed`).
  Future<String> retryFailedNotifications() async {
    final response = await _dio.post(
      '/notifications/retry-failed',
      options: Options(responseType: ResponseType.plain),
    );
    return response.data?.toString() ?? 'Failed notifications retry initiated.';
  }

  /// Fetches stock threshold alerts (`GET /stock/alerts`).
  Future<List<StockAlert>> fetchStockAlerts({int? siteId}) async {
    final Map<String, dynamic> query = {};
    if (siteId != null) query['siteId'] = siteId;

    final response = await _dio.get('/stock/alerts', queryParameters: query);
    final data = response.data;
    if (data is List) {
      return data
          .map((item) => StockAlert.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
