import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:woodapp/core/config/env.dart';
import 'package:woodapp/core/storage/storage_service.dart';
import 'package:woodapp/core/utils/view_status.dart';
import 'package:woodapp/features/notifications/controllers/notification_controller.dart';
import 'package:woodapp/features/notifications/models/app_notification.dart';
import 'package:woodapp/features/notifications/models/stock_alert.dart';
import 'package:woodapp/features/notifications/models/transfer_notification.dart';
import 'package:woodapp/features/notifications/models/transferred_article_item.dart';
import 'package:woodapp/features/notifications/services/notification_service.dart';
import 'package:woodapp/features/notifications/views/notifications_view.dart';
import 'package:woodapp/features/production/controllers/production_controller.dart';
import 'package:woodapp/features/production/controllers/production_personnel_controller.dart';
import 'package:woodapp/features/production/models/production_order.dart';
import 'package:woodapp/features/production/models/production_personnel_models.dart';
import 'package:woodapp/features/production/services/production_service.dart';
import 'package:woodapp/features/production/views/production_personnel_view.dart';
import 'package:woodapp/routes/app_pages.dart';
import 'package:woodapp/routes/app_routes.dart';

/// Mock JWT helper for testing different roles and permission states.
String _createMockJwt({
  String userId = '42',
  String role = 'Admin',
  String isManagingProduction = 'true',
  Map<String, dynamic>? permissions,
}) {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'nameid': userId,
            'email': 'artisan@woodapp.com',
            'role': role,
            'IsManagingProduction': isManagingProduction,
            'EnterpriseId': '1',
            if (permissions != null) ...{'Permissions': permissions},
          }),
        ),
      )
      .replaceAll('=', '');
  return '$header.$payload.mockSignature';
}

/// Fake notification service implementing Phase D.1 transfer article details.
class FakeD1NotificationService extends NotificationService {
  List<AppNotification> unreadsToReturn = [];
  List<TransferNotification> transfersToReturn = [];
  List<StockAlert> stockAlertsToReturn = [];
  List<TransferredArticleItem> detailsToReturn = [];

  final List<int> dismissedTransferIds = [];
  final List<int> dismissedNotificationIds = [];
  bool shouldThrowOnDetails = false;
  int fetchDetailsCallCount = 0;

  @override
  Future<List<AppNotification>> fetchUnreads() async => List.from(unreadsToReturn);

  @override
  Future<List<TransferNotification>> getMissedNotifications(int userId) async =>
      List.from(transfersToReturn);

  @override
  Future<List<StockAlert>> fetchStockAlerts({int? siteId}) async =>
      List.from(stockAlertsToReturn);

  @override
  Future<void> dismissNotification(int id) async {
    dismissedNotificationIds.add(id);
    dismissedTransferIds.add(id);
  }

  @override
  Future<List<TransferredArticleItem>> fetchTransferDetails({
    String? originDoc,
    String? receiptDoc,
  }) async {
    fetchDetailsCallCount++;
    if (shouldThrowOnDetails) {
      throw Exception('Simulated API failure on transfer details');
    }
    return List.from(detailsToReturn);
  }
}

/// Fake production service implementing Phase D.1 payables and other work.
class FakeD1ProductionService extends ProductionService {
  MonthlyEmployeePayableSummary? summaryToReturn;
  List<ProductionOtherWorkEntry> otherWorkToReturn = [];
  bool shouldThrowOnPayables = false;
  bool shouldThrowOnOtherWork = false;
  int? lastRequestedYear;
  int? lastRequestedMonth;

  @override
  Future<List<ProductionOrder>> fetchAll({
    ProductionStatus? status,
    int? salesSiteId,
    String? search,
  }) async {
    return [];
  }

  @override
  Future<MonthlyEmployeePayableSummary> fetchMonthlyPayableSummary({
    required int year,
    required int month,
  }) async {
    lastRequestedYear = year;
    lastRequestedMonth = month;
    if (shouldThrowOnPayables) {
      throw Exception('Simulated API failure on monthly payables');
    }
    return summaryToReturn ??
        MonthlyEmployeePayableSummary(
          year: year,
          month: month,
          totalManufacturingHours: 0,
          totalManufacturingAmount: 0,
          totalOtherHours: 0,
          totalOtherAmount: 0,
          totalPayableHours: 0,
          totalPayableAmount: 0,
          employees: [],
        );
  }

  @override
  Future<List<ProductionOtherWorkEntry>> fetchOtherWorkEntries({
    DateTime? startDate,
    DateTime? endDate,
    int? personId,
  }) async {
    if (shouldThrowOnOtherWork) {
      throw Exception('Simulated API failure on other work');
    }
    return List.from(otherWorkToReturn);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('phase_d1_test_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return tempDir.path;
        });
    await StorageService.ensureInitialized();
    EnvConfig.init(Flavor.development);
  });

  setUp(() async {
    Get.testMode = true;
  });

  tearDown(() async {
    await StorageService.instance.clearSession();
    await StorageService.instance.clearTenant();
    Get.reset();
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // A. TRANSFERS TESTS
  // ─────────────────────────────────────────────────────────────────────────────
  group('A. Feature A — Transfer Details & Identity Tests', () {
    test('1. Correct transfer ID vs pending notification ID mapping', () {
      final backendJson = {
        'id': 77, // PendingNotification primary key in database
        'targetGroup': 'tenant:dev:site-2',
        'createdAt': '2026-10-21T10:00:00.000Z',
        'content': jsonEncode({
          'TransferId': 204, // StockTransfer business ID
          'Reference': 'TR-26-204',
          'OriginSite': 'Dépôt Central Sfax',
          'ItemsCount': 3,
          'AdditionalData': jsonEncode({
            'ExitDocNumber': 'BS-SORTIE-204',
            'ReceiptDocNumber': 'BR-DEST-204',
          }),
        }),
      };

      final transfer = TransferNotification.fromPendingJson(backendJson);

      // Business ID must be 204
      expect(transfer.id, equals(204));
      // DB ID must be 77
      expect(transfer.pendingNotificationId, equals(77));
      expect(transfer.transferRef, equals('TR-26-204'));
      expect(transfer.originSiteName, equals('Dépôt Central Sfax'));
      expect(transfer.destinationSiteId, equals(2));
      expect(transfer.exitDocNumber, equals('BS-SORTIE-204'));
      expect(transfer.receiptDocNumber, equals('BR-DEST-204'));
      expect(transfer.itemsCount, equals(3));
    });

    final testDate = DateTime(2026, 10, 21);

    test('2. Missing site names do not display misleading #0 values', () {
      // Transfer with missing/zero sites
      final transferWithNoSite = TransferNotification(
        id: 10,
        transferRef: 'TR-NO-SITE',
        originSite: 0,
        date: testDate,
        itemsCount: 1,
        exitDocNumber: '',
        receiptDocNumber: '',
        destinationSiteId: 0,
      );

      expect(transferWithNoSite.displayOriginSite, equals('Site indisponible'));
      expect(transferWithNoSite.displayDestinationSite, equals('Site indisponible'));
      expect(transferWithNoSite.displayOriginSite.contains('#0'), isFalse);
      expect(transferWithNoSite.displayDestinationSite.contains('#0'), isFalse);

      // Transfer with known human-readable site name
      final transferWithName = TransferNotification(
        id: 11,
        transferRef: 'TR-WITH-NAME',
        originSite: 0,
        originSiteName: 'Dépôt Bois Tunis',
        date: testDate,
        itemsCount: 2,
        exitDocNumber: '',
        receiptDocNumber: '',
        destinationSiteId: 3,
        destinationSiteName: 'Chantier Mansour',
      );

      expect(transferWithName.displayOriginSite, equals('Dépôt Bois Tunis'));
      expect(transferWithName.displayDestinationSite, equals('Chantier Mansour'));
    });

    test('3. TransferredArticleItem correctly maps reference, description, and quantity', () {
      final backendItemJson = {
        'id': 501,
        'refMerchandise': 'ART-CHENE-75',
        'description': 'Planches Chêne Massif 75mm',
        'quantity': 18.75,
        'unit': 'm³',
        'refPaquet': 'PAQ-CH-01',
        'origine': 'Dépôt Sfax',
        'destination': 'Dépôt Tunis',
        'docSortie': 'BS-501',
        'docReception': 'BR-501',
      };

      final item = TransferredArticleItem.fromJson(backendItemJson);

      expect(item.id, equals(501));
      expect(item.articleReference, equals('ART-CHENE-75'));
      expect(item.description, equals('Planches Chêne Massif 75mm'));
      expect(item.quantity, equals(18.75));
      expect(item.unit, equals('m³'));
      expect(item.packageReference, equals('PAQ-CH-01'));
      expect(item.originSiteName, equals('Dépôt Sfax'));
      expect(item.destinationSiteName, equals('Dépôt Tunis'));
    });

    test('4. Dismissal continues to use the correct transfer ID', () async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(),
      );

      final fakeService = FakeD1NotificationService();
      final controller = NotificationController(service: fakeService, enablePolling: false);

      final transfer = TransferNotification(
        id: 888, // Business transfer ID
        pendingNotificationId: 99,
        transferRef: 'TR-888',
        originSite: 1,
        date: testDate,
        itemsCount: 2,
        exitDocNumber: 'BL-888',
        receiptDocNumber: 'BR-888',
        destinationSiteId: 2,
      );

      controller.transferNotifications.add(transfer);
      controller.transferDetails[888] = [
        const TransferredArticleItem(
          id: 1,
          articleReference: 'ART-TEST',
          description: 'Desc',
          quantity: 5,
        ),
      ];

      await controller.dismiss(888, isTransfer: true);

      expect(fakeService.dismissedTransferIds, equals([888]));
      expect(controller.transferNotifications.isEmpty, isTrue);
      // Cleaned up cached details
      expect(controller.transferDetails.containsKey(888), isFalse);
    });

    test('5. Expanding transfer loads details without repeated API requests', () async {
      final fakeService = FakeD1NotificationService();
      fakeService.detailsToReturn = [
        const TransferredArticleItem(
          id: 1,
          articleReference: 'BOIS-ROUGE-50',
          description: 'Bois Rouge 50x150 Traité',
          quantity: 12.5,
          unit: 'm³',
          packageReference: 'PAQ-01',
        ),
        const TransferredArticleItem(
          id: 2,
          articleReference: 'BOIS-BLANC-25',
          description: 'Bois Blanc 25x100 Standard',
          quantity: 8.0,
          unit: 'm³',
        ),
      ];

      final controller = NotificationController(service: fakeService, enablePolling: false);

      final transfer = TransferNotification(
        id: 101,
        transferRef: 'TR-101',
        originSite: 1,
        date: testDate,
        itemsCount: 2,
        exitDocNumber: 'BS-101',
        receiptDocNumber: 'BR-101',
        destinationSiteId: 2,
      );

      controller.transferNotifications.add(transfer);

      // 1. Expand the card
      controller.toggleTransferExpanded(transfer);
      expect(controller.expandedTransferIds.contains(101), isTrue);
      await controller.loadTransferDetails(transfer);

      expect(fakeService.fetchDetailsCallCount, equals(1));
      expect(controller.transferDetails[101]!.length, equals(2));
      expect(controller.transferDetails[101]![0].articleReference, equals('BOIS-ROUGE-50'));

      // 2. Toggling off and on again reuses cache without second network call
      controller.toggleTransferExpanded(transfer); // collapsed
      expect(controller.expandedTransferIds.contains(101), isFalse);

      controller.toggleTransferExpanded(transfer); // re-expanded
      expect(controller.expandedTransferIds.contains(101), isTrue);
      await controller.loadTransferDetails(transfer);

      expect(fakeService.fetchDetailsCallCount, equals(1)); // Still 1, no duplicate call
    });

    test('6. API failure produces safe error state with retry mechanism', () async {
      final fakeService = FakeD1NotificationService();
      fakeService.shouldThrowOnDetails = true;

      final controller = NotificationController(service: fakeService, enablePolling: false);

      final transfer = TransferNotification(
        id: 102,
        transferRef: 'TR-ERROR',
        originSite: 1,
        date: testDate,
        itemsCount: 1,
        exitDocNumber: 'BS-ERR',
        receiptDocNumber: 'BR-ERR',
        destinationSiteId: 2,
      );

      controller.transferNotifications.add(transfer);
      await controller.loadTransferDetails(transfer);

      expect(controller.loadingTransferDetails[102], isFalse);
      expect(controller.errorTransferDetails[102], isNotNull);
      expect(controller.errorTransferDetails[102], contains('Impossible de charger'));
    });

    testWidgets('7. Card displays prominent transfer number, human site names, and multiple articles', (tester) async {
      await StorageService.instance.saveSession(token: _createMockJwt());

      final fakeService = FakeD1NotificationService();
      fakeService.detailsToReturn = [
        const TransferredArticleItem(
          id: 1,
          articleReference: 'CHENE-RUSTIQUE',
          description: 'Chêne Rustique 40mm',
          quantity: 25.0,
          unit: 'm³',
          packageReference: 'PAQ-CH-99',
        ),
      ];

      final controller = NotificationController(service: fakeService, enablePolling: false);
      final transfer = TransferNotification(
        id: 700,
        transferRef: 'TR-700-ALPHA',
        originSite: 0,
        originSiteName: 'Dépôt Expéditeur Sfax',
        date: testDate,
        itemsCount: 1,
        exitDocNumber: 'BS-SORTIE-700',
        receiptDocNumber: 'BR-700',
        destinationSiteId: 0,
        destinationSiteName: 'Chantier Tunis Nord',
      );

      fakeService.transfersToReturn = [transfer];
      controller.transferNotifications.add(transfer);
      Get.put<NotificationController>(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: NotificationsView(),
        ),
      );
      await tester.pumpAndSettle();

      // Verified: Prominent transfer reference
      expect(find.text('TR-700-ALPHA'), findsOneWidget);
      // Verified: Human-readable site names (no #0)
      expect(find.text('Dépôt Expéditeur Sfax'), findsOneWidget);
      expect(find.text('Chantier Tunis Nord'), findsOneWidget);
      expect(find.textContaining('#0'), findsNothing);
      expect(find.text('Doc Sortie: BS-SORTIE-700'), findsOneWidget);

      // Expand to view articles
      expect(find.text('Voir les articles transférés'), findsOneWidget);
      await tester.tap(find.text('Voir les articles transférés'));
      await tester.pumpAndSettle();

      // Articles rendered
      expect(find.text('CHENE-RUSTIQUE'), findsOneWidget);
      expect(find.text('Chêne Rustique 40mm'), findsOneWidget);
      expect(find.text('25 m³'), findsOneWidget);
      expect(find.text('Paquet: PAQ-CH-99'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // B. STOCK NOTIFICATION IDENTITY TESTS
  // ─────────────────────────────────────────────────────────────────────────────
  group('B. Feature B — Stock Notification Identity Tests', () {
    test('1. Article reference is prioritized over package reference', () {
      final backendStockJson = {
        'id': 10,
        'articleReference': 'ART-PIN-SYLVESTRE',
        'merchandiseDescription': 'Pin Sylvestre Traité Classe 4',
        'packageReference': 'PAQ-PIN-2026',
        'stockQuantity': 4.5,
        'minimumStock': 15.0,
        'unit': 'm³',
        'siteName': 'Dépôt Sfax',
      };

      final alert = StockAlert.fromJson(backendStockJson);

      // Article reference must be ART-PIN-SYLVESTRE, NOT the package reference
      expect(alert.articleReference, equals('ART-PIN-SYLVESTRE'));
      expect(alert.articleCode, equals('ART-PIN-SYLVESTRE'));
      // Description must be the article/merchandise description
      expect(alert.description, equals('Pin Sylvestre Traité Classe 4'));
      // Package reference preserved separately
      expect(alert.packageReference, equals('PAQ-PIN-2026'));
      expect(alert.currentStock, equals(4.5));
      expect(alert.minThreshold, equals(15.0));
      expect(alert.unit, equals('m³'));
      expect(alert.siteName, equals('Dépôt Sfax'));
    });

    test('2. Missing description handles gracefully without inventing values', () {
      final minimalJson = {
        'id': 20,
        'articleReference': 'ART-SIMPLE',
        'stockQuantity': 2.0,
        'minimumStock': 10.0,
      };

      final alert = StockAlert.fromJson(minimalJson);

      expect(alert.articleReference, equals('ART-SIMPLE'));
      expect(alert.description, equals(''));
      expect(alert.packageReference, isNull);
      expect(alert.unit, isNull);
    });

    testWidgets('3. Stock card renders prominent article reference, clear description, and quantity values', (tester) async {
      await StorageService.instance.saveSession(token: _createMockJwt());

      final fakeService = FakeD1NotificationService();
      fakeService.stockAlertsToReturn = [
        const StockAlert(
          id: 1,
          articleReference: 'ART-FRENE-50',
          description: 'Frêne Blanc d\'Amérique 50mm',
          packageReference: 'PAQ-FR-02',
          currentStock: 3.25,
          minThreshold: 12.0,
          unit: 'm³',
          siteName: 'Dépôt Central',
        ),
      ];

      final controller = NotificationController(service: fakeService, enablePolling: false);
      Get.put<NotificationController>(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: NotificationsView(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Stock tab
      await tester.tap(find.text('Stock'));
      await tester.pumpAndSettle();

      // Verified: Article reference is prominent
      expect(find.text('ART-FRENE-50'), findsOneWidget);
      // Verified: Description is clearly visible
      expect(find.text('Frêne Blanc d\'Amérique 50mm'), findsOneWidget);
      // Verified: Package reference rendered as secondary metadata
      expect(find.text('Paquet: PAQ-FR-02'), findsOneWidget);
      // Verified: Quantities with units
      expect(find.text('3.25 m³ en stock'), findsOneWidget);
      expect(find.text('Min: 12 m³'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // C. PRODUCTION PERSONNEL & PRESTATIONS TESTS
  // ─────────────────────────────────────────────────────────────────────────────
  group('C. Feature C — Production Personnel & Prestations Tests', () {
    test('1. Monthly totals and employee breakdown map correctly from API', () {
      final jsonResponse = {
        'year': 2026,
        'month': 10,
        'totalManufacturingHours': 160.0,
        'totalManufacturingAmount': 1600.0,
        'totalOtherHours': 24.5,
        'totalOtherAmount': 245.0,
        'totalPayableHours': 184.5,
        'totalPayableAmount': 1845.0,
        'employees': [
          {
            'personId': 101,
            'employeeFullName': 'Kamel Mansour',
            'manufacturingHours': 80.0,
            'manufacturingAmount': 800.0,
            'otherHours': 12.0,
            'otherAmount': 120.0,
            'totalPayableHours': 92.0,
            'totalPayableAmount': 920.0,
          },
          {
            'personId': 102,
            'employeeFullName': 'Salah Dridi',
            'manufacturingHours': 80.0,
            'manufacturingAmount': 800.0,
            'otherHours': 12.5,
            'otherAmount': 125.0,
            'totalPayableHours': 92.5,
            'totalPayableAmount': 925.0,
          },
        ],
      };

      final summary = MonthlyEmployeePayableSummary.fromJson(jsonResponse);

      expect(summary.year, equals(2026));
      expect(summary.month, equals(10));
      expect(summary.totalManufacturingHours, equals(160.0));
      expect(summary.totalManufacturingAmount, equals(1600.0));
      expect(summary.totalOtherHours, equals(24.5));
      expect(summary.totalOtherAmount, equals(245.0));
      expect(summary.totalPayableHours, equals(184.5));
      expect(summary.totalPayableAmount, equals(1845.0));
      expect(summary.employees.length, equals(2));

      final firstEmp = summary.employees[0];
      expect(firstEmp.personId, equals(101));
      expect(firstEmp.employeeFullName, equals('Kamel Mansour'));
      expect(firstEmp.manufacturingHours, equals(80.0));
      expect(firstEmp.manufacturingAmount, equals(800.0));
      expect(firstEmp.otherHours, equals(12.0));
      expect(firstEmp.otherAmount, equals(120.0));
      expect(firstEmp.totalPayableHours, equals(92.0));
      expect(firstEmp.totalPayableAmount, equals(920.0));
    });

    test('2. Month/year selection sends correct query parameters', () async {
      await StorageService.instance.saveSession(token: _createMockJwt());

      final fakeProdService = FakeD1ProductionService();
      final controller = ProductionPersonnelController(
        service: fakeProdService,
        autoFetch: false,
      );

      controller.selectedYear.value = 2026;
      controller.selectedMonth.value = 8; // August

      await controller.fetchMonthlySummary();

      expect(fakeProdService.lastRequestedYear, equals(2026));
      expect(fakeProdService.lastRequestedMonth, equals(8));

      // Advance month
      await controller.changeMonth(1); // September
      expect(controller.selectedMonth.value, equals(9));
      expect(fakeProdService.lastRequestedMonth, equals(9));

      // Year boundary wrap (from Dec to Jan of next year)
      await controller.setMonth(12);
      await controller.changeMonth(1);
      expect(controller.selectedMonth.value, equals(1));
      expect(controller.selectedYear.value, equals(2027));
      expect(fakeProdService.lastRequestedYear, equals(2027));
    });

    test('3. Unauthorized users cannot access restricted payment information', () async {
      // User without production permission and non-admin role
      await StorageService.instance.saveSession(
        token: _createMockJwt(role: 'User', isManagingProduction: 'false'),
      );

      final fakeProdService = FakeD1ProductionService();
      final controller = ProductionPersonnelController(
        service: fakeProdService,
        autoFetch: false,
      );

      expect(controller.canAccess, isFalse);

      await controller.fetchMonthlySummary();
      expect(controller.monthlyStatus.value, equals(ViewStatus.error));
      expect(controller.monthlyErrorMessage.value, contains('Accès non autorisé'));
    });

    testWidgets('4. ProductionPersonnelView renders summary cards, employee list, and outside prestations', (tester) async {
      await StorageService.instance.saveSession(token: _createMockJwt());

      final fakeProdService = FakeD1ProductionService();
      fakeProdService.summaryToReturn = MonthlyEmployeePayableSummary(
        year: 2026,
        month: 10,
        totalManufacturingHours: 120.0,
        totalManufacturingAmount: 1200.0,
        totalOtherHours: 15.0,
        totalOtherAmount: 150.0,
        totalPayableHours: 135.0,
        totalPayableAmount: 1350.0,
        employees: [
          const EmployeePayableSummaryItem(
            personId: 1,
            employeeFullName: 'Ahmed Ben Salah',
            manufacturingHours: 60.0,
            manufacturingAmount: 600.0,
            otherHours: 5.0,
            otherAmount: 50.0,
            totalPayableHours: 65.0,
            totalPayableAmount: 650.0,
          ),
        ],
      );

      fakeProdService.otherWorkToReturn = [
        ProductionOtherWorkEntry(
          id: 5,
          personId: 1,
          employeeFullName: 'Ahmed Ben Salah',
          workDate: DateTime(2026, 10, 14),
          hours: 4.0,
          hourlyRate: 10.0,
          calculatedAmount: 40.0,
          description: 'Affûtage des lames de scie circulaire',
        ),
      ];

      final controller = ProductionPersonnelController(
        service: fakeProdService,
        autoFetch: true,
      );
      Get.put<ProductionPersonnelController>(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ProductionPersonnelView(),
        ),
      );
      await tester.pumpAndSettle();

      // Header controls
      expect(find.text('Personnel & Prestations'), findsOneWidget);
      expect(find.text('Récapitulatif Mensuel'), findsOneWidget);
      expect(find.text('Hors Ordres'), findsOneWidget);

      // KPI Summary cards
      expect(find.text('1200.000 DT'), findsOneWidget);
      expect(find.text('150.000 DT'), findsOneWidget);
      expect(find.text('135.0 h'), findsOneWidget);
      expect(find.text('1350.000 DT'), findsOneWidget); // Total to pay

      // Employee breakdown
      expect(find.text('Ahmed Ben Salah'), findsOneWidget);
      expect(find.text('650.000 DT'), findsOneWidget);
      expect(find.text('65.0 h travaillées'), findsOneWidget);

      // Switch to Prestations Hors Ordres sub-tab
      await tester.tap(find.text('Hors Ordres'));
      await tester.pumpAndSettle();

      expect(find.text('Affûtage des lames de scie circulaire'), findsOneWidget);
      expect(find.text('40.000 DT'), findsOneWidget);
      expect(find.text('4.0 h à 10.000 DT/h'), findsOneWidget);
    });

    testWidgets('5. ProductionDashboardView includes navigation action to Personnel & Prestations', (tester) async {
      await StorageService.instance.saveSession(token: _createMockJwt());

      final fakeProdService = FakeD1ProductionService();
      final prodController = ProductionController(
        service: fakeProdService,
        autoFetch: false,
      );
      Get.put<ProductionController>(prodController);

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.production,
          getPages: AppPages.pages,
        ),
      );
      await tester.pumpAndSettle();

      // Navigation icon with tooltip is present in AppBar
      expect(find.byTooltip('Personnel & Prestations'), findsOneWidget);
    });
  });
}
