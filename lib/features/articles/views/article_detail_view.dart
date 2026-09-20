import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/articles_controller.dart';
import '../models/article.dart';
import '../models/stock_summary.dart';

/// [ArticleDetailView] displays complete, structured, and mobile-friendly
/// information about a selected article from the "Catalogue des Articles".
///
/// Follows the Arbor Industrial design system:
/// - Dark nocturnal surfaces / crisp light surfaces
/// - Forest green & emerald accent badges for stock and pricing
/// - Multi-tier stock intelligence (Disponible, Faible, Rupture)
/// - Visual hierarchy: Hero Header -> Pricing Grid -> Stock & Depots -> Specs -> Metadata
class ArticleDetailView extends StatelessWidget {
  const ArticleDetailView({super.key});

  // Emerald brand colors matching the Arbor Industrial theme
  static const Color _emeraldColor = Color(0xFF10B981);
  static const Color _emeraldDarkColor = Color(0xFF047857);
  static const Color _amberColor = Color(0xFFF59E0B);
  static const Color _amberDarkColor = Color(0xFFB45309);

  /// Resolves the [Article] and [StockSummary] from GetX navigation arguments.
  /// Handles both Map arguments {'article': ..., 'stockSummary': ...},
  /// direct [Article] instances, or fallback via [ArticlesController] registry.
  (Article?, StockSummary?) _resolveArguments() {
    final args = Get.arguments;

    Article? article;
    StockSummary? stockSummary;

    if (args is Map) {
      if (args['article'] is Article) {
        article = args['article'] as Article;
      }
      if (args['stockSummary'] is StockSummary) {
        stockSummary = args['stockSummary'] as StockSummary;
      }
    } else if (args is Article) {
      article = args;
    }

    // If stockSummary was not explicitly passed, attempt to look it up in ArticlesController
    if (article != null && stockSummary == null && Get.isRegistered<ArticlesController>()) {
      final controller = Get.find<ArticlesController>();
      if (article.id != null) {
        stockSummary = controller.stockMap[article.id!];
      }
    }

    // If only an int ID was passed as argument, find article in ArticlesController
    if (article == null && args is int && Get.isRegistered<ArticlesController>()) {
      final controller = Get.find<ArticlesController>();
      article = controller.filteredArticles.firstWhereOrNull((a) => a.id == args);
      if (article?.id != null) {
        stockSummary = controller.stockMap[article!.id!];
      }
    }

    return (article, stockSummary);
  }

  /// Formats currency values into Tunisian Dinar (TND) format:
  /// Standard 3-decimal places with thousands separators, e.g. `1 250,000 DT`.
  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(3).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
    return '$integerPart,${parts[1]} DT';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (article, stockSummary) = _resolveArguments();

    // Fallback view if article could not be resolved from navigation state
    if (article == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Détails de l'article"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Get.back(),
            tooltip: 'Retour',
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, size: 56, color: colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  'Article introuvable.',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Retour au catalogue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Stock calculations based on backend DTO values:
    // C#/API Contract:
    // - ArticleDto has `minquantity` (nullable double)
    // - Stock has `quantity` aggregated across all depots
    final totalStock = stockSummary?.total ?? 0;
    final minQty = article.minQuantity;
    final isOutOfStock = totalStock <= 0;
    final isLowStock = !isOutOfStock && minQty != null && minQty > 0 && totalStock <= minQty;
    final unit = article.unit?.trim().isNotEmpty == true ? article.unit!.trim() : 'PCS';
    final formattedTotalStock = formatStockQuantity(totalStock, unit);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Détails de l'article",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour',
          // GetX navigation pop supports hardware back, Android gesture, and software tap
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Fermer',
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HERO IDENTITY CARD: Image, Title, Reference, Category Tags
              _buildHeroSection(context, article),

              const SizedBox(height: 16),

              // 2. PRICING GRID: TTC, HT, TVA rate, Last Purchase Price
              _buildPricingSection(context, article),

              const SizedBox(height: 16),

              // 3. STOCK & WAREHOUSE INVENTORY: Status badge, Total, Depots breakdown
              _buildStockSection(
                context,
                article: article,
                stockSummary: stockSummary,
                totalStock: totalStock,
                formattedTotalStock: formattedTotalStock,
                unit: unit,
                isOutOfStock: isOutOfStock,
                isLowStock: isLowStock,
              ),

              const SizedBox(height: 16),

              // 4. ARTICLE DESCRIPTION (if provided)
              if (article.description != null && article.description!.trim().isNotEmpty) ...[
                _buildDescriptionSection(context, article.description!.trim()),
                const SizedBox(height: 16),
              ],

              // 5. TECHNICAL SPECIFICATIONS (Thickness, Width, Wood nature, Unit)
              _buildTechnicalSpecsSection(context, article),

              const SizedBox(height: 16),

              // 6. SYSTEM CLASSIFICATION & METADATA
              _buildMetadataSection(context, article),

              const SizedBox(height: 24),

              // 7. BOTTOM ACTION BUTTON: Ergonomic one-hand thumb tap to return
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text(
                    'Retour au catalogue',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION BUILDERS
  // ---------------------------------------------------------------------------

  /// 1. Hero Identity Header:
  /// Displays the product image, main designation, reference pill (with copy on tap),
  /// and taxonomy chips (Category, Subcategory, Wood material).
  Widget _buildHeroSection(BuildContext context, Article article) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final displayName = article.description?.trim().isNotEmpty == true
        ? article.description!.trim()
        : (article.reference ?? 'Article sans référence');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large Hero Image Preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: article.imageUrl != null && article.imageUrl!.trim().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: article.imageUrl!.trim(),
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, _, _) => _buildImagePlaceholder(theme),
                    )
                  : _buildImagePlaceholder(theme),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reference Pill with quick tap-to-copy
                if (article.reference != null && article.reference!.trim().isNotEmpty) ...[
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: article.reference!.trim()));
                          Get.snackbar(
                            'Référence copiée',
                            article.reference!.trim(),
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                            margin: const EdgeInsets.all(16),
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            colorText: colorScheme.onSurface,
                            icon: Icon(Icons.check_circle_rounded, color: colorScheme.primary),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tag_rounded,
                                size: 13,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                article.reference!.trim(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.copy_rounded,
                                size: 12,
                                color: colorScheme.primary.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // System ID badge for inventory tracking
                      if (article.id != null)
                        Text(
                          'ID: #${article.id}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // Designation / Article Name
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 12),

                // Classification tags
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Category
                    if (article.category?.label.isNotEmpty == true)
                      _buildPill(
                        icon: Icons.category_outlined,
                        label: article.category!.label,
                        bgColor: colorScheme.secondaryContainer.withValues(alpha: 0.4),
                        fgColor: colorScheme.onSecondaryContainer,
                      ),

                    // Subcategory
                    if (article.subcategory?.label.isNotEmpty == true)
                      _buildPill(
                        icon: Icons.subdirectory_arrow_right_rounded,
                        label: article.subcategory!.label,
                        bgColor: colorScheme.surfaceContainerHighest,
                        fgColor: colorScheme.onSurfaceVariant,
                      ),

                    // Wood indicator badge
                    if (article.isWood)
                      _buildPill(
                        icon: Icons.forest_outlined,
                        label: 'Bois Naturel',
                        bgColor: _emeraldColor.withValues(alpha: 0.15),
                        fgColor: isDark ? const Color(0xFF6EE7B7) : _emeraldDarkColor,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Pricing Section:
  /// Clean, prominent card presenting the sell price TTC, sell price HT,
  /// applicable TVA rate, and last purchase price.
  Widget _buildPricingSection(BuildContext context, Article article) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Tarification & Prix',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // TVA indicator if available
              if (article.tva?.label.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'TVA: ${article.tva!.label}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 20, thickness: 0.6),

          // Main Sell Price TTC Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prix de Vente TTC',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(article.sellPriceTtc),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'TTC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Secondary Price Metrics: HT and Last Purchase Price
          Row(
            children: [
              // Sell Price HT
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Prix de Vente HT',
                  value: _formatCurrency(article.sellPriceHt),
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 12),

              // Last Purchase Price TTC (if recorded in database)
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: "Dernier Achat TTC",
                  value: article.lastPurchasePriceTtc > 0
                      ? _formatCurrency(article.lastPurchasePriceTtc)
                      : '-- DT',
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Stock & Warehouse Section:
  /// Features a visual stock status banner (Disponible / Faible / Rupture),
  /// total inventory counter, minimum threshold indicator, and a per-depot breakdown list.
  Widget _buildStockSection(
    BuildContext context, {
    required Article article,
    required StockSummary? stockSummary,
    required double totalStock,
    required String formattedTotalStock,
    required String unit,
    required bool isOutOfStock,
    required bool isLowStock,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Status styling configuration
    final (statusLabel, statusBgColor, statusFgColor, statusBorderColor, statusIcon) =
        isOutOfStock
            ? (
                'Rupture de stock',
                colorScheme.errorContainer.withValues(alpha: 0.7),
                colorScheme.error,
                colorScheme.error.withValues(alpha: 0.35),
                Icons.error_outline_rounded,
              )
            : isLowStock
                ? (
                    'Stock faible',
                    _amberColor.withValues(alpha: 0.15),
                    isDark ? const Color(0xFFFBBF24) : _amberDarkColor,
                    _amberColor.withValues(alpha: 0.4),
                    Icons.warning_amber_rounded,
                  )
                : (
                    'Stock disponible',
                    _emeraldColor.withValues(alpha: 0.15),
                    isDark ? const Color(0xFF6EE7B7) : _emeraldDarkColor,
                    _emeraldColor.withValues(alpha: 0.4),
                    Icons.check_circle_outline_rounded,
                  );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Status Badge
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'État du Stock',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusBorderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusFgColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusFgColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.6),

          // Total Quantity Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formattedTotalStock,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),

              // Minimum threshold indicator (if set)
              if (article.minQuantity != null && article.minQuantity! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Seuil min: ${formatStockQuantity(article.minQuantity!, unit)} $unit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Breakdown per sales site / depot
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warehouse_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Disponibilité par Dépôt / Magasin',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16, thickness: 0.5),

                if (stockSummary != null && stockSummary.breakdown.isNotEmpty)
                  Column(
                    children: stockSummary.breakdown.map((breakdown) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                breakdown.siteName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${breakdown.formattedQuantity} ${breakdown.unit}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        'Aucun stock enregistré dans les dépôts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Full Article Description Section
  Widget _buildDescriptionSection(BuildContext context, String description) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Description Complète',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.6),
          SelectableText(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.55,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Technical Specifications (Thickness, Width, Wood properties, Unit)
  Widget _buildTechnicalSpecsSection(BuildContext context, Article article) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Collect available technical specifications from existing models
    final specs = <MapEntry<String, String>>[];

    if (article.thickness?.label.isNotEmpty == true) {
      specs.add(MapEntry('Épaisseur', article.thickness!.label));
    }
    if (article.width?.label.isNotEmpty == true) {
      specs.add(MapEntry('Largeur', article.width!.label));
    }
    if (article.unit?.trim().isNotEmpty == true) {
      specs.add(MapEntry('Unité de mesure', article.unit!.trim()));
    }
    specs.add(MapEntry(
      'Type d\'article',
      article.isWood ? 'Bois naturel' : 'Standard / Dérivé',
    ));
    if (article.minQuantity != null && article.minQuantity! > 0) {
      specs.add(MapEntry(
        'Stock minimum d\'alerte',
        '${formatStockQuantity(article.minQuantity!, article.unit)} ${article.unit ?? ''}',
      ));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Caractéristiques Techniques',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.6),

          ...specs.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isLast = idx == specs.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.key,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        item.value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const Divider(height: 1, thickness: 0.4),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// 6. System Identification & Metadata Section
  Widget _buildMetadataSection(BuildContext context, Article article) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Informations Complémentaires',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.6),

          _buildMetadataRow(
            context,
            label: 'Référence Catalogue',
            value: article.reference ?? '--',
          ),
          const Divider(height: 14, thickness: 0.4),
          _buildMetadataRow(
            context,
            label: 'Catégorie ID',
            value: '#${article.categoryId}',
          ),
          const Divider(height: 14, thickness: 0.4),
          _buildMetadataRow(
            context,
            label: 'Sous-Catégorie ID',
            value: '#${article.subcategoryId}',
          ),
          if (article.id != null) ...[
            const Divider(height: 14, thickness: 0.4),
            _buildMetadataRow(
              context,
              label: 'Identifiant Unique Système',
              value: '#${article.id}',
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune image disponible',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fgColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
