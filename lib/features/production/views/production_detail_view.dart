import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../controllers/production_controller.dart';
import '../models/production_order.dart';
import '../widgets/production_status_badge.dart';

/// Screen displaying full read-only details of a production order.
/// Strictly read-only: displays order identity, schedule, output metrics, fabrication steps,
/// and an Admin-gated production cost summary.
class ProductionDetailView extends StatefulWidget {
  const ProductionDetailView({super.key});

  @override
  State<ProductionDetailView> createState() => _ProductionDetailViewState();
}

class _ProductionDetailViewState extends State<ProductionDetailView> {
  late final ProductionController controller;
  int? orderId;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProductionController>();

    final rawArgs = Get.arguments;
    if (rawArgs is int) {
      orderId = rawArgs;
    } else if (rawArgs is ProductionOrder) {
      orderId = rawArgs.id;
      controller.selectedOrder.value = rawArgs;
    } else if (rawArgs is Map && rawArgs['id'] != null) {
      orderId = int.tryParse(rawArgs['id'].toString());
    }

    if (orderId != null) {
      // NOTE: Retrieve fresh order details from backend GET /api/production/{id}
      controller.loadOrderDetail(orderId!);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final storage = StorageService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Détail Ordre de Fabrication',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (orderId != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualiser',
              onPressed: () => controller.loadOrderDetail(orderId!),
            ),
        ],
      ),
      body: Obx(() {
        final order = controller.selectedOrder.value;
        final detailStatus = controller.detailStatus.value;

        // Loading State when no pre-cached order is available
        if (detailStatus == ViewStatus.loading && order == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error State when order could not be loaded
        if (detailStatus == ViewStatus.error && order == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 52,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.detailErrorMessage.value ??
                        'Impossible de charger les détails de l\'ordre.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.error, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (orderId != null) controller.loadOrderDetail(orderId!);
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Réessayer'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Retour au tableau de bord'),
                  ),
                ],
              ),
            ),
          );
        }

        // Null Fallback State
        if (order == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.find_in_page_outlined,
                  size: 52,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Ordre de fabrication introuvable.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Retour au tableau de bord'),
                ),
              ],
            ),
          );
        }

        // Main Read-Only Details Layout
        return RefreshIndicator(
          onRefresh: () async {
            if (orderId != null) await controller.loadOrderDetail(orderId!);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Identity & Status Card
                _buildIdentityCard(context, order, colorScheme),
                const SizedBox(height: 14),

                // 2. Planning & Schedule Card
                _buildScheduleCard(context, order, colorScheme),
                const SizedBox(height: 14),

                // 3. Output Metrics Card
                _buildOutputMetricsCard(context, order, colorScheme),
                const SizedBox(height: 14),

                // 4. Fabrication Steps Card (Read-only list)
                _buildStepsCard(context, order, colorScheme),

                // 5. Cost Summary Section (ADMIN ONLY)
                // NOTE: Strictly restricted to Admin role. Never displayed to ordinary users.
                if (storage.isAdmin) ...[
                  const SizedBox(height: 14),
                  _buildAdminCostCard(context, order, colorScheme),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Card 1: Identity, Reference, Status, and Sales Site.
  Widget _buildIdentityCard(
    BuildContext context,
    ProductionOrder order,
    ColorScheme colorScheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Reference Tag & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.reference.isNotEmpty
                        ? order.reference
                        : 'OF-#${order.id}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ProductionStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 12),

            // Description / Title
            Text(
              (order.description != null &&
                      order.description!.trim().isNotEmpty)
                  ? order.description!
                  : 'Ordre de fabrication sans description',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),

            if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order.notes!,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Sales Site & Created By Metadata
            Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Site : ${order.salesSiteName ?? 'Non spécifié'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            if (order.createdByName != null &&
                order.createdByName!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Créé par : ${order.createdByName!}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Card 2: Planning & Schedule Dates (Planned vs Actual).
  Widget _buildScheduleCard(
    BuildContext context,
    ProductionOrder order,
    ColorScheme colorScheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Planning & Délais',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Planned Dates
            Row(
              children: [
                Expanded(
                  child: _buildDateTile(
                    label: 'Début prévu',
                    dateText: _formatDate(order.plannedStartDate),
                    icon: Icons.play_arrow_outlined,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDateTile(
                    label: 'Fin prévue',
                    dateText: _formatDate(order.plannedEndDate),
                    icon: Icons.flag_outlined,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),

            // Actual Dates (when recorded)
            if (order.actualStartDate != null ||
                order.actualEndDate != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTile(
                      label: 'Début réel',
                      dateText: _formatDate(order.actualStartDate),
                      icon: Icons.history_rounded,
                      color: const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDateTile(
                      label: 'Fin réelle',
                      dateText: _formatDate(order.actualEndDate),
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required String dateText,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateText,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Card 3: Output Metrics (Planned vs Actual quantity).
  Widget _buildOutputMetricsCard(
    BuildContext context,
    ProductionOrder order,
    ColorScheme colorScheme,
  ) {
    final planned = order.plannedOutputQuantity;
    final actual = order.actualOutputQuantity;
    final ratio = (actual != null && planned > 0)
        ? (actual / planned).clamp(0.0, 1.0)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quantités Produites',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quantité Prévue',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          planned.toStringAsFixed(
                            planned.truncateToDouble() == planned ? 0 : 2,
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (actual != null && actual > 0)
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quantité Réalisée',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF047857),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          actual != null
                              ? actual.toStringAsFixed(
                                  actual.truncateToDouble() == actual ? 0 : 2,
                                )
                              : 'En attente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: actual != null
                                ? const Color(0xFF059669)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (ratio != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(ratio * 100).toStringAsFixed(0)}% réalisé',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Card 4: Fabrication Steps (Read-only step list).
  Widget _buildStepsCard(
    BuildContext context,
    ProductionOrder order,
    ColorScheme colorScheme,
  ) {
    final steps = order.steps;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.layers_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Étapes de Fabrication',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${steps.length} étape${steps.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (steps.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Aucune étape de fabrication définie pour cet ordre.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0F172A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${step.stepNumber}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  step.name.isNotEmpty
                                      ? step.name
                                      : 'Étape #${step.stepNumber}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            StepStatusBadge(status: step.status),
                          ],
                        ),
                        if (step.description != null &&
                            step.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            step.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Prévu: ${step.plannedOutputQuantity.toStringAsFixed(1)}'
                              '${step.actualOutputQuantity != null ? ' | Réalisé: ${step.actualOutputQuantity!.toStringAsFixed(1)}' : ''}',
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
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Card 5: Admin-only Cost Analysis.
  /// Gated exclusively by [StorageService.instance.isAdmin].
  Widget _buildAdminCostCard(
    BuildContext context,
    ProductionOrder order,
    ColorScheme colorScheme,
  ) {
    return Card(
      color: const Color(0xFFFFFBEB), // Amber soft tint
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFDE68A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.scale_rounded,
                      size: 18,
                      color: Color(0xFFD97706),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Analyse des Coûts',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Total Cost Highlight
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Coût Total de Production',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF78350F),
                  ),
                ),
                Text(
                  '${(order.totalProductionCost ?? 0.0).toStringAsFixed(3)} DT',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFFDE68A)),
            const SizedBox(height: 10),

            // Cost Breakdown Grid
            _buildCostLine(
              'Coût Matières',
              order.totalMaterialCost,
              const Color(0xFFD97706),
            ),
            const SizedBox(height: 6),
            _buildCostLine(
              'Coût Main d\'œuvre',
              order.totalLaborCost,
              const Color(0xFF2563EB),
            ),
            const SizedBox(height: 6),
            _buildCostLine(
              'Autres Charges',
              order.totalOtherCost,
              const Color(0xFF475569),
            ),
            if (order.unitProductionCost != null) ...[
              const SizedBox(height: 6),
              _buildCostLine(
                'Coût Unitaire',
                order.unitProductionCost,
                const Color(0xFF059669),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostLine(String title, double? amount, Color dotColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF78350F)),
            ),
          ],
        ),
        Text(
          '${(amount ?? 0.0).toStringAsFixed(3)} DT',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF451A03),
          ),
        ),
      ],
    );
  }
}
