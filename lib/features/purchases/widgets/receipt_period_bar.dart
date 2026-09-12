import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/receipts_controller.dart';

/// Dynamic accounting period navigation card directly cloning
/// the month/year navigation, quick day bar, and month pills from
/// fo-acya-app/elance-app.ui/src/app/purchases/page.tsx.
class ReceiptPeriodBar extends StatelessWidget {
  final ReceiptsController controller;

  const ReceiptPeriodBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- TOP SECTION: MONTH & YEAR NAVIGATOR WITH QUICK DAY FILTER ---
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                // Previous Month Button
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  iconSize: 22,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Mois précédent',
                  onPressed: controller.prevMonth,
                ),

                // Active Month & Year display
                Obx(() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${controller.currentMonthName} ${controller.selectedYear}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        'Période d\'activité',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  );
                }),

                // Next Month Button
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  iconSize: 22,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Mois suivant',
                  onPressed: controller.nextMonth,
                ),

                const Spacer(),

                // "TOUT LE MOIS" / Day picker trigger badge
                Obx(() {
                  final day = controller.selectedDay.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      day == 0 ? 'TOUT LE MOIS' : 'JOUR $day',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Color(0xFF92400E),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // --- HORIZONTAL DAY FILTER SCROLLER ---
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? colorScheme.outlineVariant.withValues(alpha: 0.2)
                      : const Color(0xFFF1F5F9),
                ),
                bottom: BorderSide(
                  color: isDark
                      ? colorScheme.outlineVariant.withValues(alpha: 0.2)
                      : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: Obx(() {
              final activeDay = controller.selectedDay.value;
              final maxDays = controller.daysInCurrentMonth;

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: maxDays + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final day = index; // 0 = Tout le mois, 1..maxDays = days
                  final isSelected = activeDay == day;

                  return Center(
                    child: InkWell(
                      onTap: () => controller.setDay(day),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: day == 0 ? 10 : 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFB45309) // Amber-700
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          day == 0 ? 'TOUS' : '$day',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // --- HORIZONTAL MONTHS SHORTCUT PILLS ---
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Obx(() {
              final selectedMonth = controller.selectedMonth;

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 12,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final monthNum = index + 1;
                  final isSelected = selectedMonth == monthNum;
                  final label = ReceiptsController.shortMonthNames[index];

                  return Center(
                    child: InkWell(
                      onTap: () => controller.selectMonth(monthNum),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF78350F) // Deep amber
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
