import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

/// Interactive Year & Month filter bar widget for the Admin Analytics section.
/// Matches the design and behavior of fo-acya-app/elance-app.ui/src/app/analytics/page.tsx.
/// Allows selecting the active fiscal year and month (or 'Tous les mois') with immediate reactive refresh.
class AnalyticsFilterBarWidget extends StatelessWidget {
  final HomeController controller;

  const AnalyticsFilterBarWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final currentYear = controller.selectedYear.value;
      final currentMonth = controller.selectedMonth.value;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Leading Calendar Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),

            // 1. Year Selector (Dropdown menu)
            PopupMenuButton<int>(
              initialValue: currentYear,
              tooltip: 'Sélectionner l\'année',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              color: colorScheme.surface,
              elevation: 6,
              onSelected: (year) => controller.updateYear(year),
              itemBuilder: (context) {
                return controller.availableYears.map((year) {
                  final isSelected = year == currentYear;
                  return PopupMenuItem<int>(
                    value: year,
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Année $year',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                      ],
                    ),
                  );
                }).toList();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Année $currentYear',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            // Subtle vertical divider line
            Container(
              height: 20,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),

            // 2. Month Selector (Dropdown menu)
            PopupMenuButton<int?>(
              initialValue: currentMonth,
              tooltip: 'Sélectionner le mois',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              color: colorScheme.surface,
              elevation: 6,
              onSelected: (month) => controller.updateMonth(month),
              itemBuilder: (context) {
                return HomeController.monthOptions.entries.map((entry) {
                  final isSelected = entry.key == currentMonth;
                  return PopupMenuItem<int?>(
                    value: entry.key,
                    height: 38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                      ],
                    ),
                  );
                }).toList();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        HomeController.monthOptions[currentMonth] ?? 'Tous les mois',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
