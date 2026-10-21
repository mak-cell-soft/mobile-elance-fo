import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:woodapp/features/notifications/views/notifications_view.dart';
import 'package:woodapp/core/config/env.dart';
import 'package:woodapp/core/storage/storage_service.dart';
import 'package:woodapp/core/utils/view_status.dart';
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

  List<TransferNotification> transfersToReturn = [];
  int getMissedNotificationsCallCount = 0;
  bool shouldThrowOnMissed = false;
  Completer<List<TransferNotification>>? inFlightTransferCompleter;
  final List<int> dismissCalls = [];

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
    getMissedNotificationsCallCount++;
    if (shouldThrowOnMissed) {
      throw Exception('Simulated transfers endpoint failure');
    }
    if (inFlightTransferCompleter != null) {
      return inFlightTransferCompleter!.future;
    }
    return List.from(transfersToReturn);
  }

  @override
  Future<List<StockAlert>> fetchStockAlerts({int? siteId}) async {
    return [];
  }

  @override
  Future<void> markAsRead(int id) async {
    markAsReadCalls.add(id);
  }

  @override
  Future<void> dismissNotification(int id) async {
    dismissCalls.add(id);
  }
}

TransferNotification _createTransferNotification({
  required int id,
  int? pendingNotificationId,
  String transferRef = 'TR-2026-001',
  int originSite = 1,
  int destinationSiteId = 2,
  int itemsCount = 3,
}) {
  return TransferNotification(
    id: id,
    pendingNotificationId: pendingNotificationId,
    transferRef: transferRef,
    originSite: originSite,
    date: DateTime.now(),
    itemsCount: itemsCount,
    exitDocNumber: 'BL-001',
    receiptDocNumber: 'BR-001',
    destinationSiteId: destinationSiteId,
  );
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

  group('Phase D Transfer Notifications & Lifecycle Tests', () {
    test('1. Opening/revisiting the Notifications screen refreshes transfers', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '42', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      fakeService.unreadsToReturn = [];
      fakeService.transfersToReturn = [
        _createTransferNotification(id: 1001, transferRef: 'TR-INITIAL'),
      ];

      final controller = NotificationController(service: fakeService, enablePolling: false);
      await controller.loadAll();

      expect(controller.transferNotifications.length, equals(1));
      expect(controller.transferNotifications.first.transferRef, equals('TR-INITIAL'));
      expect(fakeService.getMissedNotificationsCallCount, equals(1));

      // New transfer arrives while user is navigating elsewhere
      fakeService.transfersToReturn = [
        _createTransferNotification(id: 1001, transferRef: 'TR-INITIAL'),
        _createTransferNotification(id: 1002, transferRef: 'TR-NEW-ARRIVED'),
      ];

      // Screen is opened or revisited
      await controller.onScreenOpened();

      expect(fakeService.getMissedNotificationsCallCount, equals(2));
      expect(controller.transferNotifications.length, equals(2));
      expect(controller.transferNotifications[1].transferRef, equals('TR-NEW-ARRIVED'));
    });

    test('2a. Valid transfer notification with explicit payload relatedEntityType refreshes transfers', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '42', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      fakeService.unreadsToReturn = [];
      fakeService.transfersToReturn = [];

      final controller = NotificationController(service: fakeService, enablePolling: false);
      await controller.loadAll();

      expect(fakeService.getMissedNotificationsCallCount, equals(1));

      // Backend publishes transfer notification
      fakeService.transfersToReturn = [
        _createTransferNotification(id: 500, transferRef: 'TR-FCM-PUSH'),
      ];

      final message = RemoteMessage(
        data: {
          'notificationId': '200',
          'tenantSlug': 'development',
          'relatedEntityType': 'StockTransfer',
        },
      );

      await controller.onForegroundMessage(notificationId: 200, rawMessage: message);

      // Verify transfers were refreshed
      expect(fakeService.getMissedNotificationsCallCount, equals(2));
      expect(controller.transferNotifications.length, equals(1));
      expect(controller.transferNotifications.first.id, equals(500));
    });

    test('2b. Transfer notification without explicit FCM relatedEntityType falls back to unreads API inspection', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '42', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      fakeService.unreadsToReturn = [];
      fakeService.transfersToReturn = [];

      final controller = NotificationController(service: fakeService, enablePolling: false);
      await controller.loadAll();

      expect(fakeService.getMissedNotificationsCallCount, equals(1));

      // Backend sends minimalist FCM push (notificationId, tenantSlug, type, priority only)
      // but AppNotification record on API has relatedEntityType: 'StockTransfer'
      fakeService.unreadsToReturn = [
        _createNotification(
          id: 300,
          title: 'Transfert de marchandise',
          message: 'Expédition TR-404 initiée',
          relatedEntityType: 'StockTransfer',
        ),
      ];
      fakeService.transfersToReturn = [
        _createTransferNotification(id: 404, transferRef: 'TR-404'),
      ];

      final minimalistMessage = RemoteMessage(
        data: {
          'notificationId': '300',
          'tenantSlug': 'development',
          'type': '1',
          'priority': '1',
        },
      );

      await controller.onForegroundMessage(notificationId: 300, rawMessage: minimalistMessage);

      // Transfer list refreshed via API inspection fallback
      expect(fakeService.getMissedNotificationsCallCount, equals(2));
      expect(controller.transferNotifications.length, equals(1));
      expect(controller.transferNotifications.first.transferRef, equals('TR-404'));
    });

    test('3. Non-transfer notification preserves existing behavior and does NOT refresh transfers', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '42', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      fakeService.unreadsToReturn = [];
      fakeService.transfersToReturn = [
        _createTransferNotification(id: 111, transferRef: 'TR-EXISTING'),
      ];

      final controller = NotificationController(service: fakeService, enablePolling: false);
      await controller.loadAll();

      expect(fakeService.getMissedNotificationsCallCount, equals(1));

      // General system notification (e.g. general company broadcast)
      fakeService.unreadsToReturn = [
        _createNotification(
          id: 700,
          title: 'Réunion générale',
          message: 'Rendez-vous à 14h en salle de réunion',
          relatedEntityType: 'GeneralAnnouncement',
        ),
      ];

      final message = RemoteMessage(
        data: {
          'notificationId': '700',
          'tenantSlug': 'development',
          'type': '1',
        },
      );

      await controller.onForegroundMessage(notificationId: 700, rawMessage: message);

      // Verify unreads refreshed, but transfer endpoint was NOT called again
      expect(fakeService.fetchUnreadsCallCount, equals(2));
      expect(fakeService.getMissedNotificationsCallCount, equals(1));
      expect(controller.systemNotifications.first.id, equals(700));
      expect(controller.transferNotifications.first.id, equals(111));
    });

    test('4. Tenant-mismatched message is discarded by FcmService and does not trigger refresh', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '42', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      final controller = NotificationController(service: fakeService, enablePolling: false);
      Get.put<NotificationController>(controller);

      int dispatchCount = 0;
      final streamController = StreamController<RemoteMessage>();

      FcmService.instance.configureForTesting(
        notificationService: fakeService,
        tokenRetriever: () async => 'token',
        foregroundMessageStreamProvider: () => streamController.stream,
        onForegroundNotification: ({notificationId, rawMessage}) {
          dispatchCount++;
          controller.onForegroundMessage(notificationId: notificationId, rawMessage: rawMessage);
        },
      );
      await FcmService.instance.init();

      final initialUnreadCalls = fakeService.fetchUnreadsCallCount;
      final initialTransferCalls = fakeService.getMissedNotificationsCallCount;

      // Send message with tenant mismatch (socofeb != development)
      streamController.add(RemoteMessage(
        data: {
          'notificationId': '888',
          'tenantSlug': 'socofeb',
          'relatedEntityType': 'StockTransfer',
        },
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(dispatchCount, equals(0));
      expect(fakeService.fetchUnreadsCallCount, equals(initialUnreadCalls));
      expect(fakeService.getMissedNotificationsCallCount, equals(initialTransferCalls));

      await streamController.close();
    });

    test('5. App resume refreshes unreads and transfers without crashing', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '42', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      fakeService.unreadsToReturn = [];
      fakeService.transfersToReturn = [];

      final controller = NotificationController(service: fakeService, enablePolling: false);
      await controller.loadAll();

      final unreadCallsBefore = fakeService.fetchUnreadsCallCount;
      final transferCallsBefore = fakeService.getMissedNotificationsCallCount;

      // Simulate OS app resume event
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(fakeService.fetchUnreadsCallCount, equals(unreadCallsBefore + 1));
      expect(fakeService.getMissedNotificationsCallCount, equals(transferCallsBefore + 1));

      // Simulate inactive or paused state - should NOT refresh
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(fakeService.fetchUnreadsCallCount, equals(unreadCallsBefore + 1));
      expect(fakeService.getMissedNotificationsCallCount, equals(transferCallsBefore + 1));
    });

    test('6. Rapid repeated events coalesce to prevent uncontrolled overlapping requests', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '42', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      final inFlight = Completer<List<TransferNotification>>();
      fakeService.inFlightTransferCompleter = inFlight;

      final controller = NotificationController(service: fakeService, enablePolling: false);

      // Trigger multiple rapid refresh requests while one is already in flight
      final f1 = controller.refreshTransfers();
      final f2 = controller.refreshTransfers();
      final f3 = controller.refreshTransfers();

      // Only 1 call should have started
      expect(fakeService.getMissedNotificationsCallCount, equals(1));

      // Resolve in-flight request
      fakeService.inFlightTransferCompleter = null;
      inFlight.complete([_createTransferNotification(id: 999)]);

      await Future.wait([f1, f2, f3]);

      // Exactly 1 additional queued fetch executed to capture pending updates, not 3
      expect(fakeService.getMissedNotificationsCallCount, equals(2));
      expect(controller.transferNotifications.length, equals(1));
    });

    test('7. Transfer-fetch failure does not prevent system notifications from loading', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '42', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      // Transfers endpoint fails (500 or timeout)
      fakeService.shouldThrowOnMissed = true;
      fakeService.unreadsToReturn = [
        _createNotification(id: 10, title: 'Notification active', message: 'Message disponible'),
      ];

      final controller = NotificationController(service: fakeService, enablePolling: false);

      // Should complete without unhandled exception
      await controller.loadAll();

      // System notifications must still be loaded and displayed
      expect(controller.systemNotifications.length, equals(1));
      expect(controller.systemNotifications.first.id, equals(10));
      // Status is ViewStatus.success because core notifications succeeded
      expect(controller.status.value, equals(ViewStatus.success));
      // Non-blocking warning is recorded
      expect(controller.errorMessage.value, contains('Certaines données'));
    });

    test('8. Transfer parsing and dismissal use correct identifiers', () async {
      // JSON returned by backend GET /stock/notifications/missed
      // item['id'] is the PendingNotification primary key (55)
      // content['TransferId'] is the StockTransfer business ID (101)
      final rawBackendPendingNotification = {
        'id': 55,
        'targetGroup': '2',
        'createdAt': '2026-10-21T10:00:00.000Z',
        'content': jsonEncode({
          'TransferId': 101,
          'Reference': 'TR-26-101',
          'OriginSite': 1,
          'ItemsCount': 5,
          'AdditionalData': jsonEncode({
            'ExitDocNumber': 'BL-SORTIE-101',
            'ReceiptDocNumber': 'BR-DEST-101',
          }),
        }),
      };

      final transfer = TransferNotification.fromPendingJson(rawBackendPendingNotification);

      // id must be the transferId (101), matching DELETE /notifications/{transferId} contract
      expect(transfer.id, equals(101));
      // pendingNotificationId must preserve the DB record ID (55)
      expect(transfer.pendingNotificationId, equals(55));
      expect(transfer.transferRef, equals('TR-26-101'));
      expect(transfer.originSite, equals(1));
      expect(transfer.itemsCount, equals(5));
      expect(transfer.exitDocNumber, equals('BL-SORTIE-101'));

      final fakeService = FakeNotificationService();
      final controller = NotificationController(service: fakeService, enablePolling: false);
      controller.transferNotifications.add(transfer);

      // Dismiss transfer
      await controller.dismiss(transfer.id, isTransfer: true);

      // Must send transfer.id (101) to backend DELETE endpoint
      expect(fakeService.dismissCalls, equals([101]));
      expect(controller.transferNotifications.isEmpty, isTrue);
    });

    test('9. Existing article-update notification behavior remains intact', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '42', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      fakeService.unreadsToReturn = [];
      fakeService.transfersToReturn = [
        _createTransferNotification(id: 777, transferRef: 'TR-UNAFFECTED'),
      ];

      final controller = NotificationController(service: fakeService, enablePolling: false);
      await controller.loadAll();

      expect(controller.unreadCount, equals(1));
      final initialTransferCalls = fakeService.getMissedNotificationsCallCount;

      // Backend publishes an Article price update notification
      fakeService.unreadsToReturn = [
        _createNotification(
          id: 901,
          title: 'Mise à jour du prix article',
          message: 'Article Bois Rouge 50x150: nouveau prix 45.000 TND',
          relatedEntityType: 'Article',
        ),
      ];

      final articleUpdatePush = RemoteMessage(
        data: {
          'notificationId': '901',
          'tenantSlug': 'development',
          'type': '2', // NotificationType.success
          'priority': '2',
        },
      );

      await controller.onForegroundMessage(notificationId: 901, rawMessage: articleUpdatePush);

      // System notification is updated and reflected in unread count
      expect(controller.systemNotifications.length, equals(1));
      expect(controller.systemNotifications.first.id, equals(901));
      expect(controller.unreadCount, equals(2)); // 1 system + 1 transfer

      // Transfer endpoint was NOT invoked for article price update
      expect(fakeService.getMissedNotificationsCallCount, equals(initialTransferCalls));
      expect(controller.transferNotifications.first.id, equals(777));
    });

    testWidgets('10. NotificationsView mounts, registers TabController and triggers onScreenOpened', (tester) async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(userId: '42', tenantSlug: 'development'),
      );
      await StorageService.instance.saveTenantSlug('development');

      final fakeService = FakeNotificationService();
      fakeService.unreadsToReturn = [];
      fakeService.transfersToReturn = [
        _createTransferNotification(id: 88, transferRef: 'TR-WIDGET-TEST'),
      ];

      final controller = NotificationController(service: fakeService, enablePolling: false);
      Get.put<NotificationController>(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: NotificationsView(),
        ),
      );
      await tester.pumpAndSettle();

      // Screen is rendered with tabs
      expect(find.text('Centre de Notifications'), findsOneWidget);
      expect(find.text('Transferts'), findsOneWidget);
      expect(find.text('Système'), findsOneWidget);
      expect(find.text('Stock'), findsOneWidget);

      // Initial onScreenOpened refresh was triggered
      expect(fakeService.getMissedNotificationsCallCount, greaterThanOrEqualTo(1));
      expect(find.text('TR-WIDGET-TEST'), findsOneWidget);
    });
  });
}
