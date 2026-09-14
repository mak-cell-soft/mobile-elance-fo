import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/view_status.dart';
import '../controllers/home_controller.dart';
import '../models/analytics_dto.dart';

/// Distinctive color palette matching Next.js elance-app.ui Recharts theme:
/// ['#1D9E75', '#534AB7', '#A39D90', '#0D9488', '#F59E0B', '#3B82F6', '#EC4899', '#06B6D4']
const List<Color> _chartColors = [
  Color(0xFF1D9E75), // Emerald
  Color(0xFF534AB7), // Indigo
  Color(0xFFA39D90), // Warm Slate
  Color(0xFF0D9488), // Deep Teal
  Color(0xFFF59E0B), // Amber
  Color(0xFF3B82F6), // Royal Blue
  Color(0xFFEC4899), // Pink Rose
  Color(0xFF06B6D4), // Cyan
];

/// Premium, responsive card component displaying "Top Ventes par Sous-Catégorie".
/// Accessible to ALL authenticated users (Non-Admin and Admin alike).
///
/// Features:
/// - Months range selector (3, 6, 12 months - default 6 months matching web)
/// - Sub-category selector chips
/// - Interactive custom-painted Donut Chart with center KPI counter
/// - Ranked article list with quantity sold and TTC revenue
/// - Interactive slice focus on tap
class TopSubCategoryChartWidget extends StatefulWidget {
  final HomeController controller;

  const TopSubCategoryChartWidget({
    super.key,
    required this.controller,
  });

  @override
  State<TopSubCategoryChartWidget> createState() => _TopSubCategoryChartWidgetState();
}

class _TopSubCategoryChartWidgetState extends State<TopSubCategoryChartWidget>
    with SingleTickerProviderStateMixin {
  int? _selectedArticleIndex;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Formats currency to Tunisian Dinar format: `4 500,000 DT`
  String _formatCurrency(double val) {
    final parts = val.toStringAsFixed(3).split('.');
    final integerPart = parts[0].replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ' ');
    return '$integerPart,${parts[1]} DT';
  }

  /// Formats integers with thousands separator: `1 250`
  String _formatQuantity(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ' ');
    }
    return val.toStringAsFixed(1).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final status = widget.controller.topSubCategoriesStatus.value;
      final subCategories = widget.controller.topSubCategories;
      final activeMonths = widget.controller.selectedTopSalesMonths.value;
      final selectedSubCat = widget.controller.selectedTopSubCategory;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER & MONTHS FILTER BAR ---
            _buildHeader(context, colorScheme, activeMonths),

            const SizedBox(height: 16),

            // --- 2. CONTENT STATES ---
            if (status == ViewStatus.loading && subCategories.isEmpty)
              _buildLoadingState(colorScheme)
            else if (status == ViewStatus.error && subCategories.isEmpty)
              _buildErrorState(colorScheme)
            else if (subCategories.isEmpty)
              _buildEmptyState('Aucune donnée de vente pour cette période.', colorScheme)
            else ...[
              // --- 2.1 SUB-CATEGORY CHIPS SELECTOR ---
              _buildSubCategoryChips(subCategories, selectedSubCat, colorScheme),

              const SizedBox(height: 20),

              // --- 2.2 ACTIVE SUB-CATEGORY CONTENT ---
              if (selectedSubCat == null || selectedSubCat.topArticles.isEmpty)
                _buildEmptyState('Aucun article vendu dans cette sous-catégorie.', colorScheme)
              else
                _buildDonutAndArticles(selectedSubCat, colorScheme),
            ],
          ],
        ),
      );
    });
  }

  /// Builds Card Title and Months [3, 6, 12] selector toggle
  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, int activeMonths) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.pie_chart_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Top Ventes par Sous-Catégorie',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Les sous-catégories les plus performantes (quantité et CA)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Period filter pills (3 mois, 6 mois, 12 mois - default 6)
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [3, 6, 12].map((m) {
                final isSelected = activeMonths == m;
                return GestureDetector(
                  onTap: () {
                    if (!isSelected) {
                      _animController.reset();
                      _animController.forward();
                      setState(() => _selectedArticleIndex = null);
                      widget.controller.updateTopSalesMonths(m);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '$m mois',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// Horizontal scrolling chip selector for available sub-categories
  Widget _buildSubCategoryChips(
    List<TopSubCategoryDto> subCategories,
    TopSubCategoryDto? activeSubCat,
    ColorScheme colorScheme,
  ) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: subCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final subCat = subCategories[index];
          final isSelected = activeSubCat?.subCategoryId == subCat.subCategoryId;

          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                _animController.reset();
                _animController.forward();
                setState(() => _selectedArticleIndex = null);
                widget.controller.selectSalesSubCat(subCat.subCategoryId);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  subCat.subCategoryName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Combines Donut CustomPainter and Ranked Articles List
  Widget _buildDonutAndArticles(TopSubCategoryDto subCat, ColorScheme colorScheme) {
    final articles = subCat.topArticles;
    final totalQty = articles.fold<double>(0.0, (sum, a) => sum + a.quantitySold);

    return Column(
      children: [
        // --- DONUT CHART CANVAS ---
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(220, 220),
                    painter: _DonutChartPainter(
                      articles: articles,
                      colors: _chartColors,
                      selectedIndex: _selectedArticleIndex,
                      animationProgress: _animation.value,
                      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    ),
                  );
                },
              ),

              // Center KPI Counter inside Donut Hole
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedArticleIndex != null && _selectedArticleIndex! < articles.length
                        ? _formatQuantity(articles[_selectedArticleIndex!].quantitySold)
                        : _formatQuantity(totalQty),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _selectedArticleIndex != null && _selectedArticleIndex! < articles.length
                          ? _chartColors[_selectedArticleIndex! % _chartColors.length]
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _selectedArticleIndex != null ? 'Unité(s)' : 'Unités vendues',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_selectedArticleIndex != null && _selectedArticleIndex! < articles.length) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(articles[_selectedArticleIndex!].revenueTTC),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- SUB-CATEGORY SUMMARY BADGE ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total CA: ${_formatCurrency(subCat.totalRevenueTTC)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16A34A),
                ),
              ),
              Text(
                '${subCat.articleCount} article(s) au total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- RANKED ARTICLES LEGEND LIST ---
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: articles.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final article = articles[index];
            final color = _chartColors[index % _chartColors.length];
            final isSelected = _selectedArticleIndex == index;
            final percentage = totalQty > 0 ? (article.quantitySold / totalQty * 100) : 0.0;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedArticleIndex = isSelected ? null : index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.1)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Rank indicator badge
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Article name & reference
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.articleName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (article.reference.isNotEmpty)
                            Text(
                              'Réf: ${article.reference}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Quantity + Percentage + Revenue
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatQuantity(article.quantitySold),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${percentage.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatCurrency(article.revenueTTC),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Shimmering loading placeholder state
  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Container(
      height: 260,
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chargement des données de vente...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Error state with retry action
  Widget _buildErrorState(ColorScheme colorScheme) {
    return Container(
      height: 200,
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 36),
          const SizedBox(height: 8),
          Text(
            'Erreur lors du chargement',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => widget.controller.loadTopSubCategories(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state display
  Widget _buildEmptyState(String message, ColorScheme colorScheme) {
    return Container(
      height: 180,
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 40,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter rendering Donut chart arcs with smooth angular sweep and padding gaps.
class _DonutChartPainter extends CustomPainter {
  final List<TopArticleDto> articles;
  final List<Color> colors;
  final int? selectedIndex;
  final double animationProgress;
  final Color backgroundColor;

  const _DonutChartPainter({
    required this.articles,
    required this.colors,
    required this.selectedIndex,
    required this.animationProgress,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseOuterRadius = size.width / 2 - 10;
    const innerRadius = 55.0;
    const strokeWidth = 26.0;

    final totalQuantity = articles.fold<double>(0.0, (sum, a) => sum + a.quantitySold);
    if (totalQuantity <= 0) return;

    // Draw background track ring
    final trackPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, (baseOuterRadius + innerRadius) / 2, trackPaint);

    double startAngle = -math.pi / 2; // Start from top 12 o'clock
    const gapAngle = 0.05; // Gap between slices in radians (approx 3 degrees)

    for (int i = 0; i < articles.length; i++) {
      final article = articles[i];
      final ratio = article.quantitySold / totalQuantity;
      final sweepAngle = (ratio * 2 * math.pi) * animationProgress;

      if (sweepAngle <= 0) continue;

      final isSelected = selectedIndex == i;
      final color = colors[i % colors.length];

      final effectiveSweep = (sweepAngle - gapAngle).clamp(0.01, 2 * math.pi);
      final currentStrokeWidth = isSelected ? strokeWidth + 6 : strokeWidth;
      final currentRadius = (baseOuterRadius + innerRadius) / 2 + (isSelected ? 3.0 : 0.0);

      final slicePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: currentRadius),
        startAngle + (gapAngle / 2),
        effectiveSweep,
        false,
        slicePaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.articles != articles;
  }
}
