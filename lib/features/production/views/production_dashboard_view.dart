import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/view_status.dart';
import '../controllers/production_controller.dart';
import '../models/production_order.dart';
import '../widgets/production_order_card.dart';

/// Main screen displaying the read-only Production Dashboard:
/// - Header with module title and subtitle
/// - KPI Summary Cards (Total, En cours, Planifiés, Terminés/Validés)
/// - Debounced search field
/// - Status filter chips
/// - Production order list with pull-to-refresh
/// - Empty, loading, and error states
class ProductionDashboardView extends GetView<ProductionController> {
  const ProductionDashboardView({super.key});

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
              'Production',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Suivi des ordres de fabrication',
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
            onPressed: () => controller.refreshOrders(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. KPI Summary Cards Section
          Obx(() => _buildSummarySection(context)),

          // 2. Search & Filter Bar Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: controller.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par référence, description, site...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: Obx(() {
                      if (controller.searchQuery.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => controller.clearSearch(),
                      );
                    }),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Status Filter Chips (Horizontal scrollable)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(() {
                    final cur = controller.selectedFilter.value;
                    return Row(
                      children: [
                        _buildFilterChip(
                          null,
                          'Tous (${controller.totalCount})',
                          cur,
                          context,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          ProductionStatus.inProgress,
                          'En cours (${controller.inProgressCount})',
                          cur,
                          context,
                          accentColor: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          ProductionStatus.planned,
                          'Planifiés (${controller.plannedCount})',
                          cur,
                          context,
                          accentColor: const Color(0xFF475569),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          ProductionStatus.completed,
                          'Terminés (${controller.orders.where((o) => o.status == ProductionStatus.completed).length})',
                          cur,
                          context,
                          accentColor: const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          ProductionStatus.validated,
                          'Validés (${controller.orders.where((o) => o.status == ProductionStatus.validated).length})',
                          cur,
                          context,
                          accentColor: const Color(0xFF059669),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          ProductionStatus.cancelled,
                          'Annulés (${controller.cancelledCount})',
                          cur,
                          context,
                          accentColor: const Color(0xFFE11D48),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),

          // 3. Orders List Body
          Expanded(
            child: Obx(() {
              // Loading State
              if (controller.status.value == ViewStatus.loading &&
                  controller.orders.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Error State / Tenant Disabled State
              if (controller.status.value == ViewStatus.error &&
                  controller.orders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          controller.isModuleDisabledForTenant.value
                              ? Icons.lock_outline_rounded
                              : Icons.error_outline_rounded,
                          size: 52,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.errorMessage.value ??
                              'Erreur lors du chargement des ordres de fabrication',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!controller.isModuleDisabledForTenant.value)
                          ElevatedButton.icon(
                            onPressed: () => controller.fetchOrders(),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Réessayer'),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => Get.back(),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
                            label: const Text('Retour à l\'accueil'),
                          ),
                      ],
                    ),
                  ),
                );
              }

              final list = controller.filteredOrders;

              // Empty State
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.precision_manufacturing_outlined,
                          size: 60,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.orders.isEmpty
                              ? 'Aucun ordre de fabrication'
                              : 'Aucun ordre correspondant',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.searchQuery.value.isNotEmpty ||
                                  controller.selectedFilter.value != null
                              ? 'Essayez de réinitialiser vos filtres ou vos termes de recherche.'
                              : 'Aucun ordre de fabrication n\'est actuellement enregistré.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (controller.selectedFilter.value != null ||
                            controller.searchQuery.value.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              controller.setFilter(null);
                              controller.clearSearch();
                            },
                            icon: const Icon(
                              Icons.filter_alt_off_rounded,
                              size: 16,
                            ),
                            label: const Text('Réinitialiser les filtres'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              // Normal Orders List with Pull-to-refresh
              return RefreshIndicator(
                onRefresh: () => controller.refreshOrders(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return ProductionOrderCard(order: list[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Builds the top KPI Summary Cards row.
  Widget _buildSummarySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Card 1: Total
          Expanded(
            child: _buildKpiTile(
              context,
              title: 'Total',
              count: controller.totalCount,
              icon: Icons.layers_outlined,
              color: const Color(0xFF0F172A),
              bgColor: const Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(width: 8),

          // Card 2: En cours (Active accent)
          Expanded(
            child: _buildKpiTile(
              context,
              title: 'En cours',
              count: controller.inProgressCount,
              icon: Icons.play_circle_outline_rounded,
              color: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
            ),
          ),
          const SizedBox(width: 8),

          // Card 3: Planifiés
          Expanded(
            child: _buildKpiTile(
              context,
              title: 'Planifiés',
              count: controller.plannedCount,
              icon: Icons.schedule_rounded,
              color: const Color(0xFF475569),
              bgColor: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(width: 8),

          // Card 4: Terminés / Validés
          Expanded(
            child: _buildKpiTile(
              context,
              title: 'Terminés',
              count: controller.completedOrValidatedCount,
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF059669),
              bgColor: const Color(0xFFECFDF5),
              subtitle: 'Validés inclus',
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single compact KPI summary tile.
  Widget _buildKpiTile(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 16, color: color),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.75),
              ),
              maxLines: 1,
            ),
        ],
      ),
    );
  }

  /// Builds an interactive status filter chip.
  Widget _buildFilterChip(
    ProductionStatus? status,
    String label,
    ProductionStatus? currentStatus,
    BuildContext context, {
    Color? accentColor,
  }) {
    final isSelected = status == currentStatus;
    final color = accentColor ?? const Color(0xFF0F172A);

    return InkWell(
      onTap: () => controller.setFilter(status),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
