import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/storage/storage_service.dart';
import '../controllers/articles_controller.dart';
import '../models/article.dart';
import '../models/stock_summary.dart';

/// [ArticleDetailView] displays a simplified, clean, and mobile-friendly
/// view of an article from the catalogue.
///
/// Business Information visible to ordinary users:
/// 1. Description (Primary Title)
/// 2. Reference (Clearly visible tag with tap-to-copy)
/// 3. Catalogue Price (TTC) with TND formatting
/// 4. Stock overview and breakdown by associated sales site / dépôt
///
/// Additional Information for Admin:
/// 5. Purchase Price (Prix d'achat TTC) — gated by [StorageService.isAdmin]
class ArticleDetailView extends StatelessWidget {
  const ArticleDetailView({super.key});

  // Emerald & Amber brand colors matching the Arbor Industrial theme
  static const Color _emeraldColor = Color(0xFF10B981);
  static const Color _emeraldDarkColor = Color(0xFF047857);
  static const Color _amberColor = Color(0xFFF59E0B);
  static const Color _amberDarkColor = Color(0xFFB45309);

  /// Resolves the [Article] and [StockSummary] from GetX navigation arguments.
  /// Handles Map arguments, direct [Article] instances, or fallback via [ArticlesController].
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
    if (article != null &&
        stockSummary == null &&
        Get.isRegistered<ArticlesController>()) {
      final controller = Get.find<ArticlesController>();
      if (article.id != null) {
        stockSummary = controller.stockMap[article.id!];
      }
    }

    // If only an int ID was passed as argument, find article in ArticlesController
    if (article == null &&
        args is int &&
        Get.isRegistered<ArticlesController>()) {
      final controller = Get.find<ArticlesController>();
      article = controller.filteredArticles.firstWhereOrNull(
        (a) => a.id == args,
      );
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
                Icon(
                  Icons.inventory_2_outlined,
                  size: 56,
                  color: colorScheme.outline,
                ),
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

    // Stock calculations based on backend DTO values
    final totalStock = stockSummary?.total ?? 0;
    final minQty = article.minQuantity;
    final isOutOfStock = totalStock <= 0;
    final isLowStock =
        !isOutOfStock && minQty != null && minQty > 0 && totalStock <= minQty;
    final unit = article.unit?.trim().isNotEmpty == true
        ? article.unit!.trim()
        : 'PCS';
    final formattedTotalStock = formatStockQuantity(totalStock, unit);

    // Check Admin privilege via existing StorageService
    final isAdmin = StorageService.instance.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Détails de l'article",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour',
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
              // 1. IDENTITY CARD: Image (if available), Description as primary title, Reference badge
              _buildIdentityCard(context, article),

              const SizedBox(height: 16),

              // 2. CATALOGUE PRICE (TTC): Prominently displayed for all users
              _buildCataloguePriceCard(context, article),

              // 3. PURCHASE PRICE (TTC): Gated strictly for Admin users only
              // Completely excluded from widget tree for unauthorized users
              if (isAdmin) ...[
                const SizedBox(height: 16),
                _buildPurchasePriceCard(context, article),
              ],

              const SizedBox(height: 16),

              // 4. STOCK & SALES SITES BREAKDOWN: Total inventory and per-depot breakdown
              _buildStockSection(
                context,
                stockSummary: stockSummary,
                totalStock: totalStock,
                formattedTotalStock: formattedTotalStock,
                unit: unit,
                isOutOfStock: isOutOfStock,
                isLowStock: isLowStock,
              ),

              const SizedBox(height: 24),

              // 5. ERGONOMIC BOTTOM RETURN BUTTON
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

  /// 1. Identity Card:
  /// Primary Title is the Description, with Reference displayed prominently.
  Widget _buildIdentityCard(BuildContext context, Article article) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final displayName = article.description?.trim().isNotEmpty == true
        ? article.description!.trim()
        : (article.reference ?? "Article sans référence");

    final hasImage =
        article.imageUrl != null && article.imageUrl!.trim().isNotEmpty;

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
          // Header Image (only if available)
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl!.trim(),
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Reference Pill & Category Tag
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Reference Pill with quick tap-to-copy
                    if (article.reference != null &&
                        article.reference!.trim().isNotEmpty)
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: article.reference!.trim()),
                          );
                          Get.snackbar(
                            'Référence copiée',
                            article.reference!.trim(),
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                            margin: const EdgeInsets.all(16),
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            colorText: colorScheme.onSurface,
                            icon: Icon(
                              Icons.check_circle_rounded,
                              color: colorScheme.primary,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(
                              alpha: 0.5,
                            ),
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
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                article.reference!.trim(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.copy_rounded,
                                size: 12,
                                color: colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Category Badge (if present)
                    if (article.category?.label.isNotEmpty == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.category!.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Primary Business Title: Description
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Catalogue Price Card:
  /// Prominently displays the sell price TTC in Tunisian Dinar (TND) with clear TTC badge.
  Widget _buildCataloguePriceCard(BuildContext context, Article article) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sell_outlined, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Prix Catalogue',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'TTC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.6),

          // Price value row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatCurrency(article.sellPriceTtc),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TTC',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Purchase Price Card (Admin Only):
  /// Rendered exclusively for users with Admin/SuperAdmin privileges.
  Widget _buildPurchasePriceCard(BuildContext context, Article article) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final purchasePrice = article.lastPurchasePriceTtc > 0
        ? _formatCurrency(article.lastPurchasePriceTtc)
        : '-- DT';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFD97706,
            ).withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_outlined,
                size: 20,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              Text(
                "Prix d'achat TTC",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFD97706).withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.6),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                purchasePrice,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD97706),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Dernier achat TTC',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 4. Stock & Warehouse Section:
  /// Displays total stock quantity, status pill (Disponible / Faible / Rupture),
  /// and the clean breakdown per sales site / dépôt.
  Widget _buildStockSection(
    BuildContext context, {
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
    final (
      statusLabel,
      statusBgColor,
      statusFgColor,
      statusBorderColor,
      statusIcon,
    ) = isOutOfStock
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
      padding: const EdgeInsets.all(18),
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
              Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: colorScheme.primary,
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
              Text(
                'Stock Global',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Breakdown per sales site / depot
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
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
                              size: 15,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                breakdown.siteName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
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
}
