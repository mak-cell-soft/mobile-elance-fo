import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:woodapp/core/storage/storage_service.dart';
import 'package:woodapp/features/articles/models/app_variable_ref.dart';
import 'package:woodapp/features/articles/models/article.dart';
import 'package:woodapp/features/articles/models/category_ref.dart';
import 'package:woodapp/features/articles/models/stock_summary.dart';
import 'package:woodapp/features/articles/views/article_detail_view.dart';

/// Helper to generate a well-formed JWT token with a specified user role for tests.
String _createMockJwt(String role) {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'nameid': '42',
            'email': 'testuser@woodapp.com',
            'role': role,
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
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return Directory.systemTemp.path;
        });
    await StorageService.ensureInitialized();
  });

  setUp(() async {
    Get.testMode = true;
  });

  tearDown(() async {
    await StorageService.instance.clearSession();
    Get.reset();
  });

  final mockArticle = Article(
    id: 42,
    reference: 'CH-25-150',
    description: 'Planche Chêne Massif 25mm',
    categoryId: 1,
    subcategoryId: 2,
    isWood: true,
    unit: 'M3',
    sellPriceHt: 120.000,
    sellPriceTtc: 142.800,
    lastPurchasePriceTtc: 95.500,
    isDeleted: false,
    minQuantity: 5.0,
    category: CategoryRef(id: 1, reference: 'BOIS', description: 'Bois Noble'),
    subcategory: CategoryRef(id: 2, reference: 'CHENE', description: 'Chêne'),
    tva: AppVariableRef(id: 1, name: 'TVA19', valuetext: '19%'),
    thickness: AppVariableRef(id: 2, name: 'TH25', valuetext: '25 mm'),
    width: AppVariableRef(id: 3, name: 'W150', valuetext: '150 mm'),
  );

  final mockStockSummary = StockSummary(
    total: 18.5,
    breakdown: [
      StockSiteBreakdown(siteName: 'Dépôt Central', quantity: 12.0, unit: 'M3'),
      StockSiteBreakdown(
        siteName: 'Boutique Sousse',
        quantity: 6.5,
        unit: 'M3',
      ),
    ],
  );

  testWidgets(
    'Ordinary authenticated user sees Description, Reference, Stock per site, and Catalogue Price (TTC), but NOT Purchase Price or technical clutter',
    (WidgetTester tester) async {
      // 1. Simulate ordinary authenticated user (role: 'User')
      await StorageService.instance.saveSession(token: _createMockJwt('User'));
      expect(StorageService.instance.isAdmin, isFalse);

      await tester.pumpWidget(GetMaterialApp(home: const SizedBox()));

      Get.to(
        () => const ArticleDetailView(),
        arguments: {'article': mockArticle, 'stockSummary': mockStockSummary},
      );
      await tester.pumpAndSettle();

      // Verify AppBar title
      expect(find.text("Détails de l'article"), findsOneWidget);

      // 1. Description is displayed as primary title
      expect(find.text('Planche Chêne Massif 25mm'), findsOneWidget);

      // 2. Reference is clearly visible in the reference tag
      expect(find.text('CH-25-150'), findsOneWidget);

      // 3. Catalogue Price (TTC) is displayed prominently
      expect(find.text('Prix Catalogue'), findsOneWidget);
      expect(find.textContaining('142,800 DT'), findsOneWidget);
      expect(find.text('TTC'), findsWidgets);

      // 4. Stock overview and sales-site breakdown are displayed
      expect(find.text('État du Stock'), findsOneWidget);
      expect(find.text('Stock disponible'), findsOneWidget);
      expect(find.textContaining('18.500'), findsOneWidget);
      expect(find.text('M3'), findsWidgets);
      expect(find.text('Dépôt Central'), findsOneWidget);
      expect(find.text('Boutique Sousse'), findsOneWidget);
      expect(find.text('12.000 M3'), findsOneWidget);
      expect(find.text('6.500 M3'), findsOneWidget);

      // 5. SECURITY CHECK: Purchase price must NOT be visible to ordinary user
      expect(find.textContaining("Prix d'achat"), findsNothing);
      expect(find.textContaining("Dernier Achat"), findsNothing);
      expect(find.textContaining('95,500 DT'), findsNothing);
      expect(find.text('ADMIN'), findsNothing);

      // 6. CLUTTER REMOVAL CHECK: Technical specs & internal IDs must NOT be displayed
      expect(find.text('25 mm'), findsNothing);
      expect(find.text('150 mm'), findsNothing);
      expect(find.text('Bois Naturel'), findsNothing);
      expect(find.text('TVA: 19%'), findsNothing);
      expect(find.textContaining('Prix de Vente HT'), findsNothing);
      expect(find.textContaining('120,000 DT'), findsNothing);
      expect(find.textContaining('Catégorie ID'), findsNothing);
      expect(find.textContaining('Sous-Catégorie ID'), findsNothing);
      expect(find.textContaining('#42'), findsNothing);
    },
  );

  testWidgets(
    'Authorized Admin user sees all required business details PLUS Purchase Price (Prix d\'achat TTC)',
    (WidgetTester tester) async {
      // 1. Simulate authorized Admin user (role: 'Admin')
      await StorageService.instance.saveSession(token: _createMockJwt('Admin'));
      expect(StorageService.instance.isAdmin, isTrue);

      await tester.pumpWidget(GetMaterialApp(home: const SizedBox()));

      Get.to(
        () => const ArticleDetailView(),
        arguments: {'article': mockArticle, 'stockSummary': mockStockSummary},
      );
      await tester.pumpAndSettle();

      // Required business fields are visible
      expect(find.text('Planche Chêne Massif 25mm'), findsOneWidget);
      expect(find.text('CH-25-150'), findsOneWidget);
      expect(find.text('Prix Catalogue'), findsOneWidget);
      expect(find.textContaining('142,800 DT'), findsOneWidget);
      expect(find.text('Dépôt Central'), findsOneWidget);

      // ADMIN ONLY: Purchase Price must be visible with ADMIN badge
      expect(find.text("Prix d'achat TTC"), findsOneWidget);
      expect(find.textContaining('95,500 DT'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('Dernier achat TTC'), findsOneWidget);

      // CLUTTER REMOVAL CHECK: Unnecessary sections remain absent even for Admin
      expect(find.text('25 mm'), findsNothing);
      expect(find.text('150 mm'), findsNothing);
      expect(find.text('TVA: 19%'), findsNothing);
      expect(find.textContaining('Prix de Vente HT'), findsNothing);
      expect(find.textContaining('Catégorie ID'), findsNothing);
    },
  );

  testWidgets(
    'ArticleDetailView displays "Stock faible" when total stock is at or below minQuantity',
    (WidgetTester tester) async {
      await StorageService.instance.saveSession(token: _createMockJwt('User'));

      final lowStockArticle = Article(
        id: 99,
        reference: 'REF-LOW',
        description: 'Article Stock Faible',
        categoryId: 1,
        subcategoryId: 2,
        isWood: false,
        unit: 'PCS',
        sellPriceHt: 10.0,
        sellPriceTtc: 11.9,
        lastPurchasePriceTtc: 8.0,
        isDeleted: false,
        minQuantity: 10.0,
      );

      final lowStockSummary = StockSummary(
        total: 4.0,
        breakdown: [
          StockSiteBreakdown(
            siteName: 'Dépôt Central',
            quantity: 4.0,
            unit: 'PCS',
          ),
        ],
      );

      await tester.pumpWidget(GetMaterialApp(home: const SizedBox()));

      Get.to(
        () => const ArticleDetailView(),
        arguments: {
          'article': lowStockArticle,
          'stockSummary': lowStockSummary,
        },
      );
      await tester.pumpAndSettle();

      expect(find.text('Stock faible'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('4 PCS'), findsOneWidget);
      expect(find.text('Dépôt Central'), findsOneWidget);
    },
  );

  testWidgets(
    'ArticleDetailView displays "Rupture de stock" when stock is zero or negative',
    (WidgetTester tester) async {
      await StorageService.instance.saveSession(token: _createMockJwt('User'));

      final outOfStockArticle = Article(
        id: 100,
        reference: 'REF-OUT',
        description: 'Article En Rupture',
        categoryId: 1,
        subcategoryId: 2,
        isWood: false,
        unit: 'PCS',
        sellPriceHt: 5.0,
        sellPriceTtc: 5.95,
        lastPurchasePriceTtc: 4.0,
        isDeleted: false,
        minQuantity: 5.0,
      );

      final outOfStockSummary = StockSummary(total: 0.0, breakdown: []);

      await tester.pumpWidget(GetMaterialApp(home: const SizedBox()));

      Get.to(
        () => const ArticleDetailView(),
        arguments: {
          'article': outOfStockArticle,
          'stockSummary': outOfStockSummary,
        },
      );
      await tester.pumpAndSettle();

      expect(find.text('Rupture de stock'), findsOneWidget);
      expect(
        find.text('Aucun stock enregistré dans les dépôts'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ArticleDetailView renders graceful fallback when article argument is null',
    (WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(home: const SizedBox()));

      Get.to(() => const ArticleDetailView(), arguments: null);
      await tester.pumpAndSettle();

      expect(find.text('Article introuvable.'), findsOneWidget);
      expect(find.text('Retour au catalogue'), findsOneWidget);
    },
  );
}
