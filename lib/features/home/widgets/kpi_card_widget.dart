import 'package:flutter/material.dart';

/// Modern KPI Metric Card widget following executive design guidelines.
/// Displays metric titles like "CA Mois" or "CA Mois Achat" with formatted TND values,
/// custom icons, subtle gradients, and trend indicators.
class KpiCardWidget extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color accentColor;
  final String periodLabel;
  final bool isPurchase;

  const KpiCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.periodLabel,
    this.isPurchase = false,
  });

  /// Formats currency values in TND format (e.g., 12 345,678 DT)
  String _formatCurrency(double val) {
    final parts = val.toStringAsFixed(3).split('.');
    final integerPart = parts[0].replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ' ');
    return '$integerPart,${parts[1]} DT';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon Badge & Trend Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPurchase
                      ? const Color(0xFFFEF3C7) // Light Amber
                      : const Color(0xFFDCFCE7), // Light Emerald
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPurchase ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                      size: 13,
                      color: isPurchase ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      periodLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPurchase ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title Label
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),

          // Large Value Text
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCurrency(value),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
