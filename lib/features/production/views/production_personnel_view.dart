import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/view_status.dart';
import '../controllers/production_personnel_controller.dart';
import '../models/production_personnel_models.dart';

const List<String> _monthNames = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

/// Mobile view presenting Production Personnel & Prestations:
/// - Month & year navigation
/// - Subview switcher (Monthly calculated summary vs Outside-order prestations)
/// - 4 Compact summary KPI cards
/// - Employee-by-employee calculated payment breakdown with expandable detail
/// - Standalone outside-order prestations list
/// - Respects role authorization and tenant isolation
class ProductionPersonnelView extends GetView<ProductionPersonnelController> {
  const ProductionPersonnelView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personnel & Prestations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Rémunérations de production',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () => controller.refreshActiveView(),
          ),
        ],
      ),
      body: Obx(() {
        if (!controller.canAccess) {
          return _buildUnauthorizedState(context, colorScheme);
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshActiveView(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // 1. Period Selector & SubView Switcher Bar
              _buildHeaderControls(context, colorScheme),
              const SizedBox(height: 14),

              // 2. SubView Content
              if (controller.activeSubView.value == PersonnelSubView.monthly)
                _buildMonthlyPayablesSection(context, colorScheme)
              else
                _buildOtherWorkSection(context, colorScheme),
            ],
          ),
        );
      }),
    );
  }

  // ── Header Controls (Period Navigation & Switcher) ─────────────────────────

  Widget _buildHeaderControls(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        // Month / Year Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Mois précédent',
                visualDensity: VisualDensity.compact,
                onPressed: () => controller.changeMonth(-1),
              ),
              Obx(() {
                final monthIdx = controller.selectedMonth.value - 1;
                final monthName = (monthIdx >= 0 && monthIdx < _monthNames.length)
                    ? _monthNames[monthIdx]
                    : 'Mois ${controller.selectedMonth.value}';
                final year = controller.selectedYear.value;

                return InkWell(
                  onTap: () => _showMonthYearPicker(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '$monthName $year',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded, size: 18),
                      ],
                    ),
                  ),
                );
              }),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Mois suivant',
                visualDensity: VisualDensity.compact,
                onPressed: () => controller.changeMonth(1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // SubView Switcher Pills
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSubViewPill(
                  title: 'Récapitulatif Mensuel',
                  icon: Icons.calculate_outlined,
                  isSelected: controller.activeSubView.value == PersonnelSubView.monthly,
                  colorScheme: colorScheme,
                  onTap: () => controller.setSubView(PersonnelSubView.monthly),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildSubViewPill(
                  title: 'Hors Ordres',
                  icon: Icons.handyman_outlined,
                  isSelected: controller.activeSubView.value == PersonnelSubView.otherWork,
                  colorScheme: colorScheme,
                  badgeCount: controller.otherWorkList.length,
                  onTap: () => controller.setSubView(PersonnelSubView.otherWork),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubViewPill({
    required String title,
    required IconData icon,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── SUBVIEW 1: Monthly Payables ───────────────────────────────────────────

  Widget _buildMonthlyPayablesSection(BuildContext context, ColorScheme colorScheme) {
    final status = controller.monthlyStatus.value;
    final summary = controller.summary.value;
    final error = controller.monthlyErrorMessage.value;

    if (status == ViewStatus.loading && summary == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Calcul des rémunérations en cours...'),
            ],
          ),
        ),
      );
    }

    if (status == ViewStatus.error && summary == null) {
      return _buildErrorState(
        context,
        colorScheme,
        message: error ?? 'Impossible de charger le récapitulatif mensuel.',
        onRetry: () => controller.fetchMonthlySummary(),
      );
    }

    if (summary == null || summary.employees.isEmpty) {
      return Column(
        children: [
          if (summary != null) ...[
            _buildSummaryKpiGrid(context, summary, colorScheme),
            const SizedBox(height: 18),
          ],
          _buildEmptyState(
            context,
            colorScheme,
            icon: Icons.hourglass_empty_rounded,
            title: 'Aucune activité ce mois',
            message:
                'Aucune session d\'ordre de fabrication ni prestation hors ordres n\'a été pointée pour cette période.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 KPI Summary Cards
        _buildSummaryKpiGrid(context, summary, colorScheme),
        const SizedBox(height: 20),

        // Employee Breakdown Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DÉTAIL PAR OUVRIER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${summary.employees.length} collaborateur${summary.employees.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // List of Employee Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: summary.employees.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final emp = summary.employees[index];
            return _buildEmployeeCard(context, emp, colorScheme);
          },
        ),
      ],
    );
  }

  /// 4 Responsive Summary Cards matching web implementation:
  /// 1. Fabrication (Ordres) Amount & Hours
  /// 2. Prestations Hors Ordres Amount & Hours
  /// 3. Total Heures Travaillées
  /// 4. Montant Total Calculé à Payer (Prominent amber accent)
  Widget _buildSummaryKpiGrid(
    BuildContext context,
    MonthlyEmployeePayableSummary summary,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                label: 'FABRICATION (ORDRES)',
                amountText: '${summary.totalManufacturingAmount.toStringAsFixed(3)} DT',
                subText: '${summary.totalManufacturingHours.toStringAsFixed(1)} h pointées',
                subColor: const Color(0xFF2563EB),
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                label: 'HORS ORDRES',
                amountText: '${summary.totalOtherAmount.toStringAsFixed(3)} DT',
                subText: '${summary.totalOtherHours.toStringAsFixed(1)} h diverses',
                subColor: const Color(0xFF059669),
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                label: 'TOTAL HEURES',
                amountText: '${summary.totalPayableHours.toStringAsFixed(1)} h',
                subText: '${summary.employees.length} ouvrier(s) actif(s)',
                subColor: colorScheme.onSurfaceVariant,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL À PAYER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.totalPayableAmount.toStringAsFixed(3)} DT',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFBBF24), // Vibrant Amber
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Rémunération calculée',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String amountText,
    required String subText,
    required Color subColor,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amountText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Employee Card with clear calculated totals and expandable details.
  Widget _buildEmployeeCard(
    BuildContext context,
    EmployeePayableSummaryItem emp,
    ColorScheme colorScheme,
  ) {
    return Obx(() {
      final isExpanded = controller.expandedEmployeeIds.contains(emp.personId);

      // Compute initials
      final names = emp.employeeFullName.trim().split(' ');
      final initials = names.isNotEmpty
          ? names.map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase()
          : 'OU';

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: InkWell(
          onTap: () => controller.toggleEmployeeExpanded(emp.personId),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Worker Avatar + Name + Total Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar Initials Badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Worker Name & Total Hours
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.employeeFullName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${emp.totalPayableHours.toStringAsFixed(1)} h travaillées',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Total Calculated Payment Highlight
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${emp.totalPayableAmount.toStringAsFixed(3)} DT',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),

                // Expandable Breakdown
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  // Breakdown Grid
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fabrication (Ordres)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${emp.manufacturingHours.toStringAsFixed(1)} h',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${emp.manufacturingAmount.toStringAsFixed(3)} DT',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF059669).withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hors Ordres',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${emp.otherHours.toStringAsFixed(1)} h',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${emp.otherAmount.toStringAsFixed(3)} DT',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  // ── SUBVIEW 2: Prestations Hors Ordres ─────────────────────────────────────

  Widget _buildOtherWorkSection(BuildContext context, ColorScheme colorScheme) {
    final status = controller.otherWorkStatus.value;
    final list = controller.otherWorkList;
    final error = controller.otherWorkErrorMessage.value;

    if (status == ViewStatus.loading && list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Chargement des prestations de travail...'),
            ],
          ),
        ),
      );
    }

    if (status == ViewStatus.error && list.isEmpty) {
      return _buildErrorState(
        context,
        colorScheme,
        message: error ?? 'Impossible de récupérer les prestations.',
        onRetry: () => controller.fetchOtherWork(),
      );
    }

    if (list.isEmpty) {
      return _buildEmptyState(
        context,
        colorScheme,
        icon: Icons.handyman_outlined,
        title: 'Aucune prestation hors ordres',
        message:
            'Aucune prestation de travail d\'atelier ou de maintenance enregistrée pour les filtres actifs.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PRESTATIONS HORS ORDRES (${list.length})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final entry = list[index];
            return _buildOtherWorkEntryCard(context, entry, colorScheme);
          },
        ),
      ],
    );
  }

  Widget _buildOtherWorkEntryCard(
    BuildContext context,
    ProductionOtherWorkEntry entry,
    ColorScheme colorScheme,
  ) {
    final dateStr =
        '${entry.workDate.day.toString().padLeft(2, '0')}/${entry.workDate.month.toString().padLeft(2, '0')}/${entry.workDate.year}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Date Badge + Worker Full Name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.employeeFullName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Total calculated amount
                Text(
                  '${entry.calculatedAmount.toStringAsFixed(3)} DT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            if (entry.description.isNotEmpty) ...[
              Text(
                entry.description,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Labor Hours & Hourly Rate Line
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.hours.toStringAsFixed(1)} h à ${entry.hourlyRate.toStringAsFixed(3)} DT/h',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── States & Dialogs ───────────────────────────────────────────────────────

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ColorScheme colorScheme, {
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 36, color: colorScheme.error),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colorScheme.error),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthorizedState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_outlined,
                size: 40,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Accès Restreint',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous ne disposez pas des autorisations nécessaires pour consulter les informations de rémunération du personnel de production.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final currentYear = DateTime.now().year;
        final years = [currentYear - 2, currentYear - 1, currentYear, currentYear + 1];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sélectionner la période',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                // Year pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: years.map((y) {
                    return Obx(() {
                      final isSelected = controller.selectedYear.value == y;
                      return ChoiceChip(
                        label: Text('$y'),
                        selected: isSelected,
                        onSelected: (_) => controller.setYear(y),
                      );
                    });
                  }).toList(),
                ),
                const SizedBox(height: 14),
                // Months grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, idx) {
                    final monthNum = idx + 1;
                    return Obx(() {
                      final isSelected = controller.selectedMonth.value == monthNum;
                      return OutlinedButton(
                        onPressed: () {
                          controller.setMonth(monthNum);
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          foregroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          _monthNames[idx],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
