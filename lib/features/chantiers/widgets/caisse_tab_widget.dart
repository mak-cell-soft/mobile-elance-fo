import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/chantier_detail_controller.dart';
import '../models/chantier_caisse_transaction.dart';
import 'alimenter_caisse_sheet.dart';
import 'caisse_kpi_row.dart';
import 'caisse_transaction_tile.dart';
import 'demande_argent_sheet.dart';

/// Onglet Caisse: The central financial hub of the mobile Chantier module.
/// Supports:
/// - Balance & replenishment KPIs
/// - User cash request submission ("Demander de l'argent")
/// - Admin cash injection ("Alimenter")
/// - Admin approval queue with Valider / Rejeter actions
/// - Filterable operations ledger
class CaisseTabWidget extends StatelessWidget {
  final ChantierDetailController controller;

  const CaisseTabWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final summary = controller.caisseSummary.value;
      if (summary == null) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final isAdmin = controller.isAdmin;
      final pendingList = controller.pendingRequests;
      final filteredList = controller.filteredTransactions;
      final currentFilter = controller.caisseFilter.value;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KPI Financial Header Cards
            CaisseKpiRow(summary: summary),

            const SizedBox(height: 16),

            // 2. Action Buttons Row (Role-aware)
            Row(
              children: [
                // User & Admin: "Demander de l'argent" button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => DemandeArgentSheet.show(context, controller),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      Icons.request_quote_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      'Demander de l\'argent',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                // Admin Only: "Alimenter" button
                if (isAdmin) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => AlimenterCaisseSheet.show(context, controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: const Text(
                        'Alimenter',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // 3. Admin Approval Queue Banner (Visible if Admin and there are pending requests)
            if (isAdmin && pendingList.isNotEmpty) ...[
              _buildApprovalQueue(context, pendingList),
              const SizedBox(height: 20),
            ],

            // 4. Section Header & Filter Pills
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Journal des Opérations',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${filteredList.length} opération${filteredList.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Filter Pills Horizontal Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Toutes (${controller.transactions.length})', currentFilter),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'entree',
                    'Alimentations (${controller.transactions.where((t) => t.isEntree).length})',
                    currentFilter,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'sortie',
                    'Dépenses (${controller.transactions.where((t) => t.isSortie && t.isCompleted).length})',
                    currentFilter,
                  ),
                  if (pendingList.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'pending',
                      'En attente (${pendingList.length})',
                      currentFilter,
                      accentColor: const Color(0xFFD97706),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. Transactions Ledger
            if (filteredList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 40,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Aucune opération de caisse trouvée',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  return CaisseTransactionTile(
                    transaction: filteredList[index],
                  );
                },
              ),

            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }

  Widget _buildApprovalQueue(
    BuildContext context,
    List<ChantierCaisseTransaction> pendingList,
  ) {
    final dateFormat = DateFormat('dd/MM HH:mm');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFDE68A), // Amber border
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pending_actions_rounded,
                size: 20,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Demandes d\'argent en attente (${pendingList.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Validez ou rejetez les demandes de fonds soumises par les utilisateurs terrain.',
            style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
          ),
          const SizedBox(height: 12),

          // List of pending cards
          Column(
            children: pendingList.map((req) {
              final isValidatingThis = controller.validatingTxId.value == req.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            req.reason,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${req.amount.toStringAsFixed(3)} TND',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Par : ${req.beneficiaryPersonName ?? "Utilisateur mobile"}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                        ),
                        Text(
                          dateFormat.format(req.transactionDate),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                    if (req.notes != null && req.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        req.notes!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Actions: Valider / Rejeter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Rejeter
                        TextButton.icon(
                          onPressed: isValidatingThis
                              ? null
                              : () => controller.validatePendingRequest(req.id, false),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text(
                            'Rejeter',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Valider
                        ElevatedButton.icon(
                          onPressed: isValidatingThis
                              ? null
                              : () => controller.validatePendingRequest(req.id, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: isValidatingThis
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 16),
                          label: const Text(
                            'Valider',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String key,
    String label,
    String currentFilter, {
    Color? accentColor,
  }) {
    final isSelected = key == currentFilter;
    final color = accentColor ?? const Color(0xFF2563EB);

    return InkWell(
      onTap: () => controller.setCaisseFilter(key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
