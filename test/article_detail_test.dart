import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:woodapp/features/articles/models/app_variable_ref.dart';
import 'package:woodapp/features/articles/models/article.dart';
import 'package:woodapp/features/articles/models/category_ref.dart';
import 'package:woodapp/features/articles/models/stock_summary.dart';
import 'package:woodapp/features/articles/views/article_detail_view.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('ArticleDetailView renders all article details correctly',
      (WidgetTester tester) async {
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
        StockSiteBreakdown(siteName: 'Boutique Sousse', quantity: 6.5, unit: 'M3'),
      ],
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: const SizedBox(),
        routes: {
          '/test': (_) => const ArticleDetailView(),
        },
      ),
    );

    Get.to(
      () => const ArticleDetailView(),
      arguments: {
        'article': mockArticle,
        'stockSummary': mockStockSummary,
      },
    );
    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text("Détails de l'article"), findsOneWidget);

    // Verify Reference (in hero header badge and in metadata section) and Designation/Description
    expect(find.text('CH-25-150'), findsNWidgets(2));
    expect(find.text('Planche Chêne Massif 25mm'), findsNWidgets(2));

    // Verify Category & Wood badges
    expect(find.text('Bois Noble'), findsOneWidget);
    expect(find.text('Chêne'), findsOneWidget);
    expect(find.text('Bois Naturel'), findsWidgets);

    // Verify Pricing
    expect(find.textContaining('142,800 DT'), findsOneWidget);
    expect(find.textContaining('120,000 DT'), findsOneWidget);
    expect(find.textContaining('95,500 DT'), findsOneWidget);
    expect(find.text('TVA: 19%'), findsOneWidget);

    // Verify Stock status
    expect(find.text('Stock disponible'), findsOneWidget);
    expect(find.textContaining('18.500'), findsOneWidget);
    expect(find.text('Dépôt Central'), findsOneWidget);
    expect(find.text('Boutique Sousse'), findsOneWidget);

    // Verify Technical Specs
    expect(find.text('25 mm'), findsOneWidget);
    expect(find.text('150 mm'), findsOneWidget);
    expect(find.text('M3'), findsWidgets);
  });

  testWidgets('ArticleDetailView displays "Stock faible" when stock is below minQuantity',
      (WidgetTester tester) async {
    final mockArticle = Article(
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

    final mockStockSummary = StockSummary(
      total: 4.0,
      breakdown: [
        StockSiteBreakdown(siteName: 'Dépôt Central', quantity: 4.0, unit: 'PCS'),
      ],
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: const SizedBox(),
      ),
    );

    Get.to(
      () => const ArticleDetailView(),
      arguments: {
        'article': mockArticle,
        'stockSummary': mockStockSummary,
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('Stock faible'), findsOneWidget);
  });

  testWidgets('ArticleDetailView displays "Rupture de stock" when stock is zero or negative',
      (WidgetTester tester) async {
    final mockArticle = Article(
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

    final mockStockSummary = StockSummary(
      total: 0.0,
      breakdown: [],
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: const SizedBox(),
      ),
    );

    Get.to(
      () => const ArticleDetailView(),
      arguments: {
        'article': mockArticle,
        'stockSummary': mockStockSummary,
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('Rupture de stock'), findsOneWidget);
  });
}
