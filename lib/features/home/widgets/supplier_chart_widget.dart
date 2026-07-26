import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/analytics_dto.dart';

/// Custom responsive Bar Chart widget displaying "Achats vs Règlements par Fournisseur".
/// Rendered using Flutter CustomPainter for smooth rendering, interactive touches,
/// and pixel-perfect design matching Recharts web aesthetic.
class SupplierChartWidget extends StatefulWidget {
  final List<SupplierChartPointDto> dataPoints;

  const SupplierChartWidget({super.key, required this.dataPoints});

  @override
  State<SupplierChartWidget> createState() => _SupplierChartWidgetState();
}

class _SupplierChartWidgetState extends State<SupplierChartWidget> {
  int? _selectedIndex;

  String _formatShortCurrency(double val) {
    if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}k DT';
    }
    return '${val.toStringAsFixed(0)} DT';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.dataPoints.isEmpty) {
      return Container(
        height: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: const Center(
          child: Text(
            'Aucune donnée d\'achat ou règlement sur cette période.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    // Find max value across purchases and payments for scaling
    final double maxVal = widget.dataPoints.fold(0.0, (max, item) {
      final itemMax = math.max(item.purchases, item.payments);
      return itemMax > max ? itemMax : max;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Legends
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achats vs Règlements par Fournisseur',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Comparatif des volumes d\'achats TTC et règlements',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Legend Indicators Row
          Row(
            children: [
              _buildLegendItem('Achats TTC', const Color(0xFFD97706)),
              const SizedBox(width: 16),
              _buildLegendItem('Règlements', const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 20),

          // Interactive Selected Item Details Banner
          if (_selectedIndex != null && _selectedIndex! < widget.dataPoints.length) ...[
            Builder(builder: (context) {
              final selected = widget.dataPoints[_selectedIndex!];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      selected.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      'Achats: ${_formatShortCurrency(selected.purchases)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Règl: ${_formatShortCurrency(selected.payments)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Bar Chart Canvas Horizontal Scrollable
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: widget.dataPoints.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = _selectedIndex == index;

                  final purchasesRatio = maxVal > 0 ? (item.purchases / maxVal).clamp(0.02, 1.0) : 0.02;
                  final paymentsRatio = maxVal > 0 ? (item.payments / maxVal).clamp(0.02, 1.0) : 0.02;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = isSelected ? null : index;
                      });
                    },
                    child: Container(
                      width: 68,
                      margin: const EdgeInsets.only(right: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Dual Bar Columns
                          SizedBox(
                            height: 140,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Purchases Bar (Amber)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 18,
                                  height: 140 * purchasesRatio,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Payments Bar (Emerald)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 18,
                                  height: 140 * paymentsRatio,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF34D399), Color(0xFF10B981)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Supplier Name Label
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
