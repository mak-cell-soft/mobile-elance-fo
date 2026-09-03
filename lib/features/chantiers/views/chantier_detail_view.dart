import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/view_status.dart';
import '../controllers/chantier_detail_controller.dart';
import '../widgets/caisse_tab_widget.dart';
import '../widgets/chantier_status_banner.dart';
import '../widgets/general_tab_widget.dart';
import '../widgets/suivi_tab_widget.dart';

/// Detail screen for a single Chantier with tabs for:
/// - Général: metadata, descriptions, dates, team
/// - Suivi: progress lifecycle timeline & alerts
/// - Caisse: financial desk, cash requests & admin approval
class ChantierDetailView extends GetView<ChantierDetailController> {
  const ChantierDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final d = controller.detail.value;
          return Text(
            d?.name ?? 'Détail du Chantier',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () => controller.loadAllData(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.detailStatus.value == ViewStatus.loading &&
            controller.detail.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.detailStatus.value == ViewStatus.error &&
            controller.detail.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 48, color: colorScheme.error),
                  const SizedBox(height: 14),
                  Text(
                    controller.detailErrorMessage.value ??
                        'Erreur lors du chargement des détails.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => controller.loadAllData(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final site = controller.detail.value;
        if (site == null) {
          return const Center(child: Text('Chantier non trouvé.'));
        }

        final pendingCount = controller.pendingCount;

        return RefreshIndicator(
          onRefresh: () => controller.loadAllData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Executive Banner
                ChantierStatusBanner(detail: site),

                const SizedBox(height: 18),

                // 2. Tab Navigation Bar (Général | Suivi | Caisse)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Tab 0: Général
                      _buildTabButton(
                        context,
                        index: 0,
                        label: 'Général',
                        icon: Icons.info_outline_rounded,
                      ),

                      // Tab 1: Suivi
                      _buildTabButton(
                        context,
                        index: 1,
                        label: 'Suivi',
                        icon: Icons.trending_up_rounded,
                      ),

                      // Tab 2: Caisse (Main)
                      _buildTabButton(
                        context,
                        index: 2,
                        label: 'Caisse',
                        icon: Icons.account_balance_wallet_outlined,
                        badgeCount: pendingCount > 0 ? pendingCount : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Tab Content
                Obx(() {
                  switch (controller.activeTab.value) {
                    case 1:
                      return SuiviTabWidget(
                        detail: site,
                        progressEntries: controller.progressEntries,
                        alerts: controller.alerts,
                      );
                    case 2:
                      return CaisseTabWidget(controller: controller);
                    case 0:
                    default:
                      return GeneralTabWidget(detail: site);
                  }
                }),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required int index,
    required String label,
    required IconData icon,
    int? badgeCount,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = controller.activeTab.value == index;

    return Expanded(
      child: InkWell(
        onTap: () => controller.activeTab.value = index,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
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
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
              if (badgeCount != null && badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706), // Amber
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
