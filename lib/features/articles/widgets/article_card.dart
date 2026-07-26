import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../models/stock_summary.dart';

/// Article card widget with integrated stock display and expandable per-site breakdown (Option B).
class ArticleCard extends StatelessWidget {
  final Article article;
  final StockSummary? stockSummary;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const ArticleCard({
    super.key,
    required this.article,
    this.stockSummary,
    this.isExpanded = false,
    this.onToggleExpand,
  });

  static const Color _emeraldColor = Color(0xFF10B981);
  static const Color _emeraldDarkColor = Color(0xFF047857);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalStock = stockSummary?.total ?? 0;
    final isOutOfStock = totalStock <= 0;
    final formattedTotal = stockSummary?.formattedTotal(article.unit) ??
        formatStockQuantity(0, article.unit);
    final unit = article.unit ?? 'PCS';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: InkWell(
        onTap: onToggleExpand,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Card Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: article.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: article.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => _placeholder(theme),
                            )
                          : _placeholder(theme),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info Center Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.description ?? article.reference ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (article.reference != null)
                          Text(
                            'Réf: ${article.reference}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (article.category?.label.isNotEmpty ?? false)
                              _tag(theme, article.category!.label),
                            if (article.isWood)
                              _tag(theme, 'Bois', color: colorScheme.secondaryContainer),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Right Side: Price & Stock Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${article.sellPriceTtc.toStringAsFixed(2)} DT',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'TTC',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Stock Badge Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? colorScheme.errorContainer.withValues(alpha: 0.7)
                              : _emeraldColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOutOfStock
                                ? colorScheme.error.withValues(alpha: 0.3)
                                : _emeraldColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOutOfStock
                                  ? Icons.error_outline_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 13,
                              color: isOutOfStock
                                  ? colorScheme.error
                                  : _emeraldDarkColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$formattedTotal $unit',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOutOfStock
                                    ? colorScheme.error
                                    : _emeraldDarkColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Expand Chevron with Label
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isExpanded ? 'Fermer' : 'Dépôts',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Expandable Stock Breakdown Panel per Depot/Site (Option B)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  margin: const EdgeInsets.only(top: 14),
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
                            'Aperçu Stock par Dépôt / Site',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16, thickness: 0.5),

                      if (stockSummary != null && stockSummary!.breakdown.isNotEmpty)
                        Column(
                          children: stockSummary!.breakdown.map((breakdown) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.storefront_outlined,
                                          size: 14,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
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
                                      ],
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
                              'Aucun stock disponible dans les dépôts',
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
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.inventory_2_outlined,
          color: theme.colorScheme.outline,
        ),
      );

  Widget _tag(ThemeData theme, String label, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color ?? theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 11,
          ),
        ),
      );
}
