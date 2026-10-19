import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../models/production_order.dart';
import 'production_status_badge.dart';

/// Card widget rendering an individual production order in the dashboard list.
/// Designed for high mobile legibility with clear typography and spatial hierarchy.
/// Strictly read-only: no edit, delete, or lifecycle mutation controls.
class ProductionOrderCard extends StatelessWidget {
  final ProductionOrder order;

  const ProductionOrderCard({super.key, required this.order});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    return '$day/$month/$year';
  }

  String _formatSchedule() {
    final start = _formatDate(order.plannedStartDate);
    final end = _formatDate(order.plannedEndDate);

    if (start.isNotEmpty && end.isNotEmpty) {
      return 'Du $start au $end';
    } else if (start.isNotEmpty) {
      return 'Début prévu: $start';
    } else if (end.isNotEmpty) {
      return 'Fin prévue: $end';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scheduleText = _formatSchedule();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to read-only details screen, passing order ID as argument
            Get.toNamed(AppRoutes.productionDetail, arguments: order.id);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Reference Tag & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Reference Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        order.reference.isNotEmpty
                            ? order.reference
                            : 'OF-#${order.id}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // Status Badge
                    ProductionStatusBadge(
                      status: order.status,
                      isCompact: true,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Description / Title
                Text(
                  (order.description != null &&
                          order.description!.trim().isNotEmpty)
                      ? order.description!
                      : 'Ordre de fabrication sans description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Sales Site Info (if available)
                if (order.salesSiteName != null &&
                    order.salesSiteName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          order.salesSiteName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Bottom Row: Planned Quantity & Schedule Dates
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Planned Quantity
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Qté prévue: ${order.plannedOutputQuantity.toStringAsFixed(order.plannedOutputQuantity.truncateToDouble() == order.plannedOutputQuantity ? 0 : 2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),

                    // Schedule / Dates
                    if (scheduleText.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            scheduleText,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Text(
                            'Voir détails',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
