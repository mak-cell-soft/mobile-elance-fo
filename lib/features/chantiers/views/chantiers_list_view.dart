import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/view_status.dart';
import '../controllers/chantiers_list_controller.dart';
import '../widgets/chantier_list_card.dart';

/// Main screen displaying the list of all Chantiers,
/// with search bar, filter tabs (Tous, En cours, Alertes), and pull-to-refresh.
class ChantiersListView extends GetView<ChantiersListController> {
  const ChantiersListView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Chantiers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () => controller.refreshChantiers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                    hintText: 'Rechercher par nom, référence, lieu...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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

                // Quick Status Filters
                Obx(() {
                  final cur = controller.selectedFilter.value;
                  return Row(
                    children: [
                      _buildFilterChip('all', 'Tous (${controller.totalCount})', cur),
                      const SizedBox(width: 8),
                      _buildFilterChip('inProgress', 'En cours (${controller.inProgressCount})', cur),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'alert',
                        'Vigilance (${controller.alertCount})',
                        cur,
                        accentColor: const Color(0xFFE24B4A),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          // 2. Chantiers List Body
          Expanded(
            child: Obx(() {
              if (controller.status.value == ViewStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.status.value == ViewStatus.error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          controller.errorMessage.value ?? 'Erreur lors du chargement des chantiers',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.error),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => controller.fetchChantiers(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final list = controller.filteredChantiers;

              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.construction_rounded,
                          size: 56,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun chantier trouvé',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.searchQuery.value.isNotEmpty
                              ? 'Essayez de modifier vos termes de recherche.'
                              : 'Aucun chantier n\'est actuellement disponible.',
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

              return RefreshIndicator(
                onRefresh: () => controller.refreshChantiers(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return ChantierListCard(chantier: list[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String key,
    String label,
    String current, {
    Color? accentColor,
  }) {
    final isSelected = key == current;
    final color = accentColor ?? const Color(0xFF2563EB);

    return InkWell(
      onTap: () => controller.setFilter(key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}
