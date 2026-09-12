import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/view_status.dart';
import '../controllers/receipts_controller.dart';
import '../widgets/receipt_card.dart';
import '../widgets/receipt_detail_sheet.dart';
import '../widgets/receipt_kpi_section.dart';
import '../widgets/receipt_period_bar.dart';

/// Main Executive Bons de Réception (BR) View.
/// High-fidelity clone of the "Réceptions / BR" tab from
/// fo-acya-app/elance-app.ui/src/app/purchases/page.tsx.
class ReceiptsListView extends GetView<ReceiptsController> {
  const ReceiptsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bons de Réception (BR)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: controller.refreshReceipts,
          ),
          Obx(() {
            final hasActiveFilters = controller.searchTerm.value.isNotEmpty ||
                controller.selectedSupplierId.value != null ||
                controller.selectedDay.value != 0;

            if (!hasActiveFilters) return const SizedBox.shrink();

            return IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded),
              tooltip: 'Effacer les filtres',
              onPressed: controller.clearFilters,
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // --- 1. PERIOD SELECTOR BAR ---
          ReceiptPeriodBar(controller: controller),

          // --- 2. EXECUTIVE TOTALS / KPIS ---
          ReceiptKpiSection(controller: controller),

          // --- 3. SEARCH & SUPPLIER FILTER CONTROLS ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                // Search Input Field
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: controller.setSearchTerm,
                    decoration: InputDecoration(
                      hintText: 'N° doc, réf. BL, fournisseur...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Color(0xFFD97706),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: isDark ? colorScheme.surfaceContainer : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD97706),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Supplier Dropdown Filter
                Expanded(
                  flex: 2,
                  child: Obx(() {
                    final suppliers = controller.suppliers;
                    final selectedId = controller.selectedSupplierId.value;

                    return Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainer : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: selectedId,
                          isExpanded: true,
                          hint: Text(
                            'Fournisseur',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 20,
                            color: Color(0xFFD97706),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                'Tous les Fournisseurs',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ...suppliers.map((s) {
                              return DropdownMenuItem<int?>(
                                value: s.id,
                                child: Text(
                                  s.displayName,
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: controller.setSupplierFilter,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // --- 4. COUNT SUMMARY CHIP BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Obx(() {
              final count = controller.filteredCount;
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.layers_rounded,
                          size: 12,
                          color: Color(0xFF92400E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count document(s) trouvé(s)',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 4),

          // --- 5. DATA LIST VIEW / VIEW STATUS ---
          Expanded(
            child: Obx(() {
              switch (controller.status.value) {
                case ViewStatus.initial:
                case ViewStatus.loading:
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD97706),
                      strokeWidth: 2.5,
                    ),
                  );

                case ViewStatus.error:
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Color(0xFFE11D48),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            controller.errorMessage.value ??
                                'Impossible de charger les bons de réception.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: controller.loadReceipts,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                case ViewStatus.empty:
                case ViewStatus.success:
                  final docs = controller.filteredDocuments;

                  if (docs.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: controller.refreshReceipts,
                      color: const Color(0xFFD97706),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 40,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun Bon de Réception',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Aucune réception enregistrée pour ${controller.currentMonthName} ${controller.selectedYear}.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.refreshReceipts,
                    color: const Color(0xFFD97706),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final item = docs[index];
                        return ReceiptCard(
                          document: item,
                          onTap: () => ReceiptDetailSheet.show(context, item),
                        );
                      },
                    ),
                  );
              }
            }),
          ),
        ],
      ),
    );
  }
}
