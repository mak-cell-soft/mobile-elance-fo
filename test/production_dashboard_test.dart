import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:woodapp/core/config/env.dart';
import 'package:woodapp/core/storage/storage_service.dart';
import 'package:woodapp/core/utils/view_status.dart';
import 'package:woodapp/features/production/controllers/production_controller.dart';
import 'package:woodapp/features/production/models/production_order.dart';
import 'package:woodapp/features/production/views/production_dashboard_view.dart';
import 'package:woodapp/features/production/views/production_detail_view.dart';
import 'package:woodapp/features/tenant/models/tenant_config.dart';
import 'package:woodapp/routes/app_pages.dart';
import 'package:woodapp/routes/app_routes.dart';

/// Helper to generate a well-formed JWT token with custom claims for tests.
String _createMockJwt({
  String role = 'User',
  String isManagingProduction = 'true',
}) {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'nameid': '42',
            'email': 'artisan@woodapp.com',
            'role': role,
            'IsManagingProduction': isManagingProduction,
            'EnterpriseId': '1',
          }),
        ),
      )
      .replaceAll('=', '');
  return '$header.$payload.mockSignature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('prod_test_');
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
  // A. Feature Activation & Guard Tests
  // ─────────────────────────────────────────────────────────────────────────────
  group('A. Feature Activation & Protection Guards', () {
    test(
      'TenantConfig parses hasProductionModule and isManagingProduction',
      () {
        final configDisabled = TenantConfig.fromJson({
          'tenantId': 'test-tenant',
          'hasProductionModule': false,
          'isManagingProduction': false,
        });

        expect(configDisabled.hasProductionModule, isFalse);
        expect(configDisabled.isManagingProduction, isFalse);

        final configEnabled = TenantConfig.fromJson({
          'tenantId': 'test-tenant',
          'hasProductionModule': true,
          'isManagingProduction': true,
        });

        expect(configEnabled.hasProductionModule, isTrue);
        expect(configEnabled.isManagingProduction, isTrue);
      },
    );

    test(
      'StorageService respects JWT claim IsManagingProduction = false',
      () async {
        await StorageService.instance.saveSession(
          token: _createMockJwt(isManagingProduction: 'false'),
        );

        expect(StorageService.instance.isManagingProduction, isFalse);
        expect(StorageService.instance.hasProductionModule, isFalse);
      },
    );

    test(
      'StorageService respects JWT claim IsManagingProduction = true',
      () async {
        await StorageService.instance.saveSession(
          token: _createMockJwt(isManagingProduction: 'true'),
        );

        expect(StorageService.instance.isManagingProduction, isTrue);
        expect(StorageService.instance.hasProductionModule, isTrue);
      },
    );

    test(
      'ProductionGuardMiddleware blocks access when module is disabled',
      () async {
        await StorageService.instance.saveSession(
          token: _createMockJwt(isManagingProduction: 'false'),
        );

        final middleware = ProductionGuardMiddleware();
        final routeSettings = middleware.redirect(AppRoutes.production);

        expect(routeSettings, isNotNull);
        expect(routeSettings?.name, equals(AppRoutes.home));
      },
    );

    test(
      'ProductionGuardMiddleware allows access when module is enabled',
      () async {
        await StorageService.instance.saveSession(
          token: _createMockJwt(isManagingProduction: 'true'),
        );

        final middleware = ProductionGuardMiddleware();
        final routeSettings = middleware.redirect(AppRoutes.production);

        expect(routeSettings, isNull);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // B. Model Parsing and Serialization Tests
  // ─────────────────────────────────────────────────────────────────────────────
  group('B. Production Models & DTO Parsing', () {
    final validOrderJson = {
      'id': 101,
      'guid': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      'reference': 'OF-2026-001',
      'description': 'Table Chêne Rustique 8 Places',
      'notes': 'Finitions vernis mat',
      'salesSiteId': 3,
      'salesSiteName': 'Dépôt Central Sfax',
      'status': 'InProgress',
      'plannedStartDate': '2026-10-15T08:00:00Z',
      'plannedEndDate': '2026-10-25T17:00:00Z',
      'actualStartDate': '2026-10-16T09:00:00Z',
      'actualEndDate': null,
      'totalMaterialCost': 420.500,
      'totalLaborCost': 180.000,
      'totalOtherCost': 25.000,
      'totalProductionCost': 625.500,
      'unitProductionCost': 125.100,
      'plannedOutputQuantity': 5.0,
      'actualOutputQuantity': 2.0,
      'createdById': 7,
      'createdByName': 'Chef d\'Atelier Mansour',
      'creationDate': '2026-10-14T11:00:00Z',
      'steps': [
        {
          'id': 201,
          'productionOrderId': 101,
          'stepNumber': 1,
          'name': 'Découpe & Dégauchissage',
          'description': 'Débit des madriers',
          'status': 'Completed',
          'startDate': '2026-10-16T09:00:00Z',
          'endDate': '2026-10-16T16:00:00Z',
          'laborCost': 60.000,
          'plannedOutputQuantity': 5.0,
          'actualOutputQuantity': 5.0,
        },
        {
          'id': 202,
          'productionOrderId': 101,
          'stepNumber': 2,
          'name': 'Assemblage & Collage',
          'description': 'Assemblage du piétement',
          'status': 'InProgress',
          'startDate': '2026-10-17T08:30:00Z',
          'plannedOutputQuantity': 5.0,
        },
      ],
    };

    test('Parses full ProductionOrderDto JSON with steps accurately', () {
      final order = ProductionOrder.fromJson(validOrderJson);

      expect(order.id, equals(101));
      expect(order.reference, equals('OF-2026-001'));
      expect(order.description, equals('Table Chêne Rustique 8 Places'));
      expect(order.salesSiteName, equals('Dépôt Central Sfax'));
      expect(order.status, equals(ProductionStatus.inProgress));
      expect(order.plannedOutputQuantity, equals(5.0));
      expect(order.actualOutputQuantity, equals(2.0));
      expect(order.totalProductionCost, equals(625.500));
      expect(order.steps.length, equals(2));

      final step1 = order.steps.first;
      expect(step1.stepNumber, equals(1));
      expect(step1.name, equals('Découpe & Dégauchissage'));
      expect(step1.status, equals(ProductionStepStatus.completed));
      expect(step1.actualOutputQuantity, equals(5.0));
    });

    test(
      'Safely handles nullable dates, missing quantities, and null costs',
      () {
        final minimalJson = {
          'id': 102,
          'reference': 'OF-MINIMAL',
          'status': 'Planned',
          'salesSiteId': 1,
        };

        final order = ProductionOrder.fromJson(minimalJson);

        expect(order.id, equals(102));
        expect(order.reference, equals('OF-MINIMAL'));
        expect(order.description, isNull);
        expect(order.plannedStartDate, isNull);
        expect(order.plannedEndDate, isNull);
        expect(order.actualStartDate, isNull);
        expect(order.totalProductionCost, isNull);
        expect(order.actualOutputQuantity, isNull);
        expect(order.steps, isEmpty);
      },
    );

    test('Status enum parses both String names and int values correctly', () {
      expect(
        ProductionStatus.fromDynamic('Planned'),
        equals(ProductionStatus.planned),
      );
      expect(
        ProductionStatus.fromDynamic('InProgress'),
        equals(ProductionStatus.inProgress),
      );
      expect(
        ProductionStatus.fromDynamic('Completed'),
        equals(ProductionStatus.completed),
      );
      expect(
        ProductionStatus.fromDynamic('Validated'),
        equals(ProductionStatus.validated),
      );
      expect(
        ProductionStatus.fromDynamic('Cancelled'),
        equals(ProductionStatus.cancelled),
      );

      expect(ProductionStatus.fromDynamic(0), equals(ProductionStatus.planned));
      expect(
        ProductionStatus.fromDynamic(1),
        equals(ProductionStatus.inProgress),
      );
      expect(
        ProductionStatus.fromDynamic(2),
        equals(ProductionStatus.completed),
      );
      expect(
        ProductionStatus.fromDynamic(3),
        equals(ProductionStatus.validated),
      );
      expect(
        ProductionStatus.fromDynamic(4),
        equals(ProductionStatus.cancelled),
      );
    });

    test(
      'Unknown status value falls back safely to planned without throwing',
      () {
        expect(
          ProductionStatus.fromDynamic('UNKNOWN_STATE'),
          equals(ProductionStatus.planned),
        );
        expect(
          ProductionStatus.fromDynamic(99),
          equals(ProductionStatus.planned),
        );
        expect(
          ProductionStatus.fromDynamic(null),
          equals(ProductionStatus.planned),
        );

        expect(
          ProductionStepStatus.fromDynamic('UNKNOWN'),
          equals(ProductionStepStatus.planned),
        );
        expect(
          ProductionStepStatus.fromDynamic(99),
          equals(ProductionStepStatus.planned),
        );
        expect(
          ProductionStepStatus.fromDynamic(null),
          equals(ProductionStepStatus.planned),
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // C. Dashboard Controller & KPI Indicator Tests
  // ─────────────────────────────────────────────────────────────────────────────
  group('C. Dashboard Controller & KPI Calculations', () {
    late ProductionController controller;

    setUp(() {
      controller = ProductionController(autoFetch: false);
    });

    tearDown(() {
      controller.onClose();
    });

    final mockOrdersList = [
      ProductionOrder(
        id: 1,
        reference: 'OF-001',
        description: 'Chaises Salle à Manger',
        salesSiteName: 'Sfax',
        status: ProductionStatus.inProgress,
        plannedOutputQuantity: 10,
      ),
      ProductionOrder(
        id: 2,
        reference: 'OF-002',
        description: 'Armoire 3 Portes',
        salesSiteName: 'Tunis',
        status: ProductionStatus.inProgress,
        plannedOutputQuantity: 2,
      ),
      ProductionOrder(
        id: 3,
        reference: 'OF-003',
        description: 'Porte Fenêtre Bois',
        salesSiteName: 'Sousse',
        status: ProductionStatus.planned,
        plannedOutputQuantity: 4,
      ),
      ProductionOrder(
        id: 4,
        reference: 'OF-004',
        description: 'Buffet Bas Chene',
        salesSiteName: 'Sfax',
        status: ProductionStatus.completed,
        plannedOutputQuantity: 1,
      ),
      ProductionOrder(
        id: 5,
        reference: 'OF-005',
        description: 'Meuble TV Moderne',
        salesSiteName: 'Nabeul',
        status: ProductionStatus.validated,
        plannedOutputQuantity: 3,
      ),
      ProductionOrder(
        id: 6,
        reference: 'OF-006',
        description: 'Prototype Rejeté',
        salesSiteName: 'Tunis',
        status: ProductionStatus.cancelled,
        plannedOutputQuantity: 1,
      ),
    ];

    test(
      'Computes accurate summary counts and excludes cancelled orders from active counts',
      () {
        controller.orders.assignAll(mockOrdersList);

        expect(controller.totalCount, equals(6));
        expect(controller.inProgressCount, equals(2));
        expect(controller.plannedCount, equals(1));
        // Completed + Validated grouped count
        expect(controller.completedOrValidatedCount, equals(2));
        // Cancelled count
        expect(controller.cancelledCount, equals(1));
      },
    );

    test('Filters orders by selected status filter', () {
      controller.orders.assignAll(mockOrdersList);

      controller.setFilter(ProductionStatus.inProgress);
      expect(controller.filteredOrders.length, equals(2));
      expect(
        controller.filteredOrders.every(
          (o) => o.status == ProductionStatus.inProgress,
        ),
        isTrue,
      );

      controller.setFilter(ProductionStatus.cancelled);
      expect(controller.filteredOrders.length, equals(1));
      expect(controller.filteredOrders.first.reference, equals('OF-006'));

      controller.setFilter(null); // 'Tous'
      expect(controller.filteredOrders.length, equals(6));
    });

    test('Filters orders by debounced search query', () async {
      controller.orders.assignAll(mockOrdersList);

      controller.onSearchChanged('Chaises');
      // Wait for debounce timer (300ms)
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(controller.filteredOrders.length, equals(1));
      expect(controller.filteredOrders.first.reference, equals('OF-001'));

      controller.clearSearch();
      expect(controller.filteredOrders.length, equals(6));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // D. Dashboard & Detail Widget Tests
  // ─────────────────────────────────────────────────────────────────────────────
  group('D. Dashboard & Detail UI Rendering Tests', () {
    testWidgets(
      'Dashboard renders header, KPI cards, filter chips, and order cards',
      (tester) async {
        await StorageService.instance.saveSession(
          token: _createMockJwt(role: 'User'),
        );

        final controller = Get.put(ProductionController(autoFetch: false));
        controller.orders.assignAll([
          ProductionOrder(
            id: 11,
            reference: 'OF-BOIS-01',
            description: 'Salon Marocain Sculpté',
            salesSiteName: 'Showroom Tunis',
            status: ProductionStatus.inProgress,
            plannedOutputQuantity: 2.0,
            plannedStartDate: DateTime(2026, 10, 20),
            plannedEndDate: DateTime(2026, 10, 30),
          ),
        ]);
        controller.status.value = ViewStatus.success;

        await tester.pumpWidget(
          GetMaterialApp(home: const ProductionDashboardView()),
        );
        await tester.pumpAndSettle();

        // 1. Header is rendered
        expect(find.text('Production'), findsOneWidget);
        expect(find.text('Suivi des ordres de fabrication'), findsOneWidget);

        // 2. Summary KPI tiles are rendered
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('En cours'), findsWidgets);
        expect(find.text('Planifiés'), findsWidgets);
        expect(find.text('Terminés'), findsWidgets);

        // 3. Order Card renders fixture data
        expect(find.text('OF-BOIS-01'), findsOneWidget);
        expect(find.text('Salon Marocain Sculpté'), findsOneWidget);
        expect(find.text('Showroom Tunis'), findsOneWidget);
        expect(find.text('Qté prévue: 2'), findsOneWidget);
        expect(
          find.textContaining('Du 20/10/2026 au 30/10/2026'),
          findsOneWidget,
        );

        // 4. Verify no mutation buttons exist
        expect(find.text('Modifier'), findsNothing);
        expect(find.text('Supprimer'), findsNothing);
        expect(find.text('Valider'), findsNothing);
        expect(find.text('Démarrer'), findsNothing);
        expect(find.text('Annuler'), findsNothing);
      },
    );

    testWidgets('Ordinary user does NOT see production costs in details view', (
      tester,
    ) async {
      // Ordinary user without Admin role
      await StorageService.instance.saveSession(
        token: _createMockJwt(role: 'User'),
      );
      expect(StorageService.instance.isAdmin, isFalse);

      final controller = Get.put(ProductionController(autoFetch: false));
      final mockDetailOrder = ProductionOrder(
        id: 42,
        reference: 'OF-CONFIDENTIAL',
        description: 'Chambre à Coucher Royale',
        salesSiteName: 'Sfax',
        status: ProductionStatus.inProgress,
        plannedOutputQuantity: 1.0,
        totalMaterialCost: 850.000,
        totalLaborCost: 400.000,
        totalProductionCost: 1250.000,
        steps: [
          ProductionStep(
            id: 1,
            stepNumber: 1,
            name: 'Façonnage tête de lit',
            status: ProductionStepStatus.completed,
            plannedOutputQuantity: 1.0,
          ),
        ],
      );

      controller.selectedOrder.value = mockDetailOrder;
      controller.detailStatus.value = ViewStatus.success;

      await tester.pumpWidget(
        GetMaterialApp(home: const ProductionDetailView()),
      );
      await tester.pumpAndSettle();

      // Read-only business data is displayed
      expect(find.text('Détail Ordre de Fabrication'), findsOneWidget);
      expect(find.text('OF-CONFIDENTIAL'), findsOneWidget);
      expect(find.text('Chambre à Coucher Royale'), findsOneWidget);
      expect(find.text('Façonnage tête de lit'), findsOneWidget);

      // SECURITY CHECK: Production costs MUST NOT be displayed to non-admin
      expect(find.text('Analyse des Coûts'), findsNothing);
      expect(find.textContaining('1250.000 DT'), findsNothing);
      expect(find.textContaining('Coût Total de Production'), findsNothing);
      expect(find.text('ADMIN'), findsNothing);

      // No mutation controls
      expect(find.text('Modifier'), findsNothing);
      expect(find.text('Supprimer'), findsNothing);
    });

    testWidgets(
      'Admin user DOES see the cost analysis card with ADMIN badge in details view',
      (tester) async {
        // Authorized Admin user
        await StorageService.instance.saveSession(
          token: _createMockJwt(role: 'Admin'),
        );
        expect(StorageService.instance.isAdmin, isTrue);

        final controller = Get.put(ProductionController(autoFetch: false));
        final mockDetailOrder = ProductionOrder(
          id: 43,
          reference: 'OF-ADMIN-VIEW',
          description: 'Bureau Direction Acajou',
          salesSiteName: 'Dépôt Central',
          status: ProductionStatus.completed,
          plannedOutputQuantity: 2.0,
          actualOutputQuantity: 2.0,
          totalMaterialCost: 1100.000,
          totalLaborCost: 450.000,
          totalOtherCost: 50.000,
          totalProductionCost: 1600.000,
          unitProductionCost: 800.000,
        );

        controller.selectedOrder.value = mockDetailOrder;
        controller.detailStatus.value = ViewStatus.success;

        await tester.pumpWidget(
          GetMaterialApp(home: const ProductionDetailView()),
        );
        await tester.pumpAndSettle();

        // ADMIN ONLY: Cost card is rendered
        expect(find.text('Analyse des Coûts'), findsOneWidget);
        expect(find.text('ADMIN'), findsOneWidget);
        expect(find.text('Coût Total de Production'), findsOneWidget);
        expect(find.text('1600.000 DT'), findsOneWidget);
        expect(find.text('Coût Matières'), findsOneWidget);
        expect(find.text('1100.000 DT'), findsOneWidget);
        expect(find.text('Coût Main d\'œuvre'), findsOneWidget);
        expect(find.text('450.000 DT'), findsOneWidget);
        expect(find.text('Coût Unitaire'), findsOneWidget);
        expect(find.text('800.000 DT'), findsOneWidget);
      },
    );

    testWidgets('Dashboard renders graceful empty state when list is empty', (
      tester,
    ) async {
      await StorageService.instance.saveSession(
        token: _createMockJwt(role: 'User'),
      );

      final controller = Get.put(ProductionController(autoFetch: false));
      controller.orders.clear();
      controller.status.value = ViewStatus.success;

      await tester.pumpWidget(
        GetMaterialApp(home: const ProductionDashboardView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aucun ordre de fabrication'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets(
      'Dashboard renders error state and retry button on network error',
      (tester) async {
        await StorageService.instance.saveSession(
          token: _createMockJwt(role: 'User'),
        );

        final controller = Get.put(ProductionController(autoFetch: false));
        controller.orders.clear();
        controller.status.value = ViewStatus.error;
        controller.errorMessage.value = 'Erreur réseau de test';

        await tester.pumpWidget(
          GetMaterialApp(home: const ProductionDashboardView()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Erreur réseau de test'), findsOneWidget);
        expect(find.text('Réessayer'), findsOneWidget);
      },
    );
  });
}
