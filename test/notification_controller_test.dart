import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:woodapp/core/config/env.dart';
import 'package:woodapp/core/storage/storage_service.dart';
import 'package:woodapp/features/notifications/controllers/notification_controller.dart';
import 'package:woodapp/features/notifications/models/app_notification.dart';
import 'package:woodapp/features/notifications/models/notification_type.dart';
import 'package:woodapp/features/notifications/models/stock_alert.dart';
import 'package:woodapp/features/notifications/models/transfer_notification.dart';
import 'package:woodapp/features/notifications/services/fcm_service.dart';
import 'package:woodapp/features/notifications/services/notification_service.dart';

class FakeNotificationService extends NotificationService {
  List<AppNotification> unreadsToReturn = [];
  int fetchUnreadsCallCount = 0;
  Completer<List<AppNotification>>? inFlightFetchCompleter;
  final List<int> markAsReadCalls = [];
  bool shouldThrowOnFetch = false;

  @override
  Future<List<AppNotification>> fetchUnreads() async {
    fetchUnreadsCallCount++;
    if (shouldThrowOnFetch) {
      throw Exception('Simulated network timeout');
    }
    if (inFlightFetchCompleter != null) {
      return inFlightFetchCompleter!.future;
    }
    return List.from(unreadsToReturn);
  }

  @override
  Future<List<TransferNotification>> getMissedNotifications(int userId) async {
    return [];
  }

  @override
  Future<List<StockAlert>> fetchStockAlerts({int? siteId}) async {
    return [];
  }

  @override
  Future<void> markAsRead(int id) async {
    markAsReadCalls.add(id);
  }
}

String _createMockJwt({required String userId, required String tenantSlug, String role = 'Admin'}) {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'nameid': userId,
            'tenant_slug': tenantSlug,
            'role': role,
          }),
        ),
      )
      .replaceAll('=', '');
  return '$header.$payload.signature';
}

AppNotification _createNotification({
  required int id,
  String title = 'Test Title',
  String message = 'Test Message',
  bool isRead = false,
  String? relatedEntityType,
  String? actionUrl,
}) {
  return AppNotification(
    id: id,
    title: title,
    message: message,
    type: NotificationType.info,
    createdAt: DateTime.now(),
    isRead: isRead,
    relatedEntityType: relatedEntityType,
    actionUrl: actionUrl,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('notif_ctrl_test_');
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

  group('NotificationController Foreground & Concurrency Tests', () {
    test('An FCM event triggers an immediate unread refresh and updates the badge', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development', role: 'Admin'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      // Initially no unreads
      fakeService.unreadsToReturn = [];

      final controller = NotificationController(service: fakeService, enablePolling: false);
      await controller.loadAll();

      expect(controller.unreadCount, equals(0));
      expect(fakeService.fetchUnreadsCallCount, equals(1));

      // New notification arrives on backend
      fakeService.unreadsToReturn = [
        _createNotification(id: 101, title: 'Facture validée', message: 'Montant 1200 TND'),
      ];

      // Simulate foreground FCM event
      await controller.onForegroundMessage(notificationId: 101);

      // Verify immediate authoritative refresh occurred
      expect(fakeService.fetchUnreadsCallCount, equals(2));
      expect(controller.unreadCount, equals(1));
      expect(controller.systemNotifications.first.id, equals(101));
    });

    test('Receiving a push does not mark a notification as read', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      fakeService.unreadsToReturn = [
        _createNotification(id: 202, title: 'Alert', message: 'Action required', isRead: false),
      ];

      final controller = NotificationController(service: fakeService, enablePolling: false);
      await controller.loadAll();

      // FCM event arrives for notification 202
      await controller.onForegroundMessage(notificationId: 202);

      // markAsRead must NOT have been called
      expect(fakeService.markAsReadCalls, isEmpty);
      expect(controller.systemNotifications.first.isRead, isFalse);
    });

    test('A scheduled poll does not duplicate feedback after FCM handling', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development', role: 'Admin'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      fakeService.unreadsToReturn = [];

      final controller = NotificationController(service: fakeService, enablePolling: false);
      await controller.loadAll();

      // Push arrives for item 303
      fakeService.unreadsToReturn = [
        _createNotification(id: 303, title: 'Nouveau message', message: 'Contenu 303'),
      ];
      await controller.onForegroundMessage(notificationId: 303);

      expect(controller.systemNotifications.length, equals(1));
      expect(controller.unreadCount, equals(1));

      // Now the 30-second polling timer runs
      await controller.pollForUpdates();

      // State remains consistent, no duplication
      expect(controller.systemNotifications.length, equals(1));
      expect(controller.unreadCount, equals(1));
    });

    test('An FCM event arriving during an active poll triggers a subsequent refresh', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      final inFlightCompleter = Completer<List<AppNotification>>();
      fakeService.inFlightFetchCompleter = inFlightCompleter;

      final controller = NotificationController(service: fakeService, enablePolling: false);

      // 1. Start first poll which stays in-flight
      final firstPollFuture = controller.pollForUpdates();

      // 2. FCM event arrives while first poll is still awaiting network
      final fcmFuture = controller.onForegroundMessage(notificationId: 404);

      // Complete the first in-flight poll with item 404
      fakeService.inFlightFetchCompleter = null; // Next call returns immediately
      fakeService.unreadsToReturn = [
        _createNotification(id: 404, title: 'In-flight push', message: 'Delivered during poll'),
      ];
      inFlightCompleter.complete(fakeService.unreadsToReturn);

      await firstPollFuture;
      await fcmFuture;

      // Allow the pending refresh to execute
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify that subsequent poll was triggered to ensure consistency
      expect(fakeService.fetchUnreadsCallCount, greaterThanOrEqualTo(2));
      expect(controller.systemNotifications.length, equals(1));
      expect(controller.systemNotifications.first.id, equals(404));
    });

    test('Missing or malformed notification IDs are handled safely without exceptions', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      fakeService.unreadsToReturn = [];

      final controller = NotificationController(service: fakeService, enablePolling: false);
      await controller.loadAll();

      // Null ID
      await expectLater(controller.onForegroundMessage(notificationId: null), completes);

      // Verify controller remains operational
      expect(controller.unreadCount, equals(0));
    });

    test('API failures during polling do not crash the controller', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '1', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      fakeService.shouldThrowOnFetch = true;

      final controller = NotificationController(service: fakeService, enablePolling: false);

      // Calling onForegroundMessage when API fails should not throw
      await expectLater(controller.onForegroundMessage(notificationId: 505), completes);

      // Controller should remain initialized with 0 unreads
      expect(controller.unreadCount, equals(0));
    });

    test('Standard user notification handling does not crash', () async {
      // User with 'User' role (non-admin)
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '2', tenantSlug: 'development', role: 'User'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      fakeService.unreadsToReturn = [];

      final controller = NotificationController(service: fakeService, enablePolling: false);
      await controller.loadAll();

      // Notification arrives
      fakeService.unreadsToReturn = [
        _createNotification(id: 606, title: 'Notification Employé', message: 'Transfert assigné'),
      ];

      // Foreground event should trigger standard user alert flow without throwing
      await expectLater(controller.onForegroundMessage(notificationId: 606), completes);

      expect(controller.unreadCount, equals(1));
      expect(controller.systemNotifications.first.id, equals(606));
    });
  });
}
