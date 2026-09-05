import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/storage/storage_service.dart';
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
        child: isAdmin
            ? _buildAdminCaisseView(
                context,
                theme,
                colorScheme,
                summary,
                pendingList,
                filteredList,
                currentFilter,
              )
            : _buildCollaboratorCaisseView(
                context,
                theme,
                colorScheme,
              ),
      );
    });
  }

  /// Collaborator view: Strictly personal.
  /// - NO caisse solde / balance visible
  /// - NO alimentations / décaissements global totals visible
  /// - NO global operations ledger visible
  /// - ONLY his cash requests + approval statuses (En attente, Validée, Rejetée)
  Widget _buildCollaboratorCaisseView(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final myRequests = controller.myCashRequests;
    final pendingCount = controller.myPendingRequestsCount;
    final approvedCount = controller.myApprovedRequestsCount;
    final rejectedCount = controller.myRejectedRequestsCount;
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Collaborator Header: Espace Demandes de Caisse
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.6),
                colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Espace Demandes de Caisse',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Soumettez vos demandes de fonds et suivez leur statut d\'approbation.',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Micro-KPI badges for collaborator
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatBadge(
                    label: 'Total demandes',
                    count: '${myRequests.length}',
                    color: colorScheme.primary,
                    bgColor: colorScheme.primary.withValues(alpha: 0.1),
                    icon: Icons.list_alt_rounded,
                  ),
                  _buildStatBadge(
                    label: 'En attente',
                    count: '$pendingCount',
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                    icon: Icons.hourglass_empty_rounded,
                  ),
                  _buildStatBadge(
                    label: 'Validées',
                    count: '$approvedCount',
                    color: const Color(0xFF059669),
                    bgColor: const Color(0xFFECFDF5),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  if (rejectedCount > 0)
                    _buildStatBadge(
                      label: 'Rejetées',
                      count: '$rejectedCount',
                      color: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFEF2F2),
                      icon: Icons.cancel_outlined,
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Action Button: "Demander de l'argent"
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => DemandeArgentSheet.show(context, controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.request_quote_rounded, size: 19),
            label: const Text(
              'Demander de l\'argent',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 3. Section Title: "Mes Demandes de Fonds"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mes Demandes de Fonds',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${myRequests.length} demande${myRequests.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4. List of Collaborator Requests
        if (myRequests.isEmpty)
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
                  'Aucune demande de fonds enregistrée',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliquez sur "Demander de l\'argent" ci-dessus pour soumettre votre premier besoin de caisse.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: myRequests.length,
            itemBuilder: (context, index) {
              final req = myRequests[index];
              return _buildCollaboratorRequestCard(
                context,
                req,
                dateFormat,
                theme,
                colorScheme,
              );
            },
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  /// Single collaborator cash request card with clear status pill and details
  Widget _buildCollaboratorRequestCard(
    BuildContext context,
    ChantierCaisseTransaction req,
    DateFormat dateFormat,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    Color statusColor;
    Color statusBgColor;
    String statusTitle;
    IconData statusIcon;
    String statusExplanation;

    if (req.isPending) {
      statusColor = const Color(0xFFD97706);
      statusBgColor = const Color(0xFFFEF3C7);
      statusTitle = 'En attente';
      statusIcon = Icons.hourglass_empty_rounded;
      statusExplanation = 'En cours d\'examen par la direction';
    } else if (req.isCompleted) {
      statusColor = const Color(0xFF059669);
      statusBgColor = const Color(0xFFECFDF5);
      statusTitle = 'Validée';
      statusIcon = Icons.check_circle_rounded;
      statusExplanation = req.validationDate != null
          ? 'Approuvée le ${DateFormat('dd/MM à HH:mm').format(req.validationDate!)}'
          : 'Validée par la direction';
    } else {
      statusColor = const Color(0xFFDC2626);
      statusBgColor = const Color(0xFFFEF2F2);
      statusTitle = 'Rejetée';
      statusIcon = Icons.cancel_rounded;
      statusExplanation = 'Demande rejetée par la direction';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: req.isPending
              ? const Color(0xFFFDE68A)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: req.isPending ? 1.5 : 1.0,
        ),
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
          // Motif & Montant
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  req.reason,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${req.amount.toStringAsFixed(3)} TND',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Date & Time
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 5),
              Text(
                dateFormat.format(req.transactionDate),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          if (req.notes != null && req.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Note : ${req.notes!}',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Status Badge + Status explanation
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusExplanation,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Small stat badge with icon
  Widget _buildStatBadge({
    required String label,
    required String count,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label : ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            count,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Admin view: Full financial oversight, KPIs, alimenter action, approval queue, and ledger
  Widget _buildAdminCaisseView(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic summary,
    List<ChantierCaisseTransaction> pendingList,
    List<ChantierCaisseTransaction> filteredList,
    String currentFilter,
  ) {
    return Column(
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
        ),

        const SizedBox(height: 20),

        // 3. Admin Approval Queue Banner (Visible if Admin and there are pending requests)
        if (pendingList.isNotEmpty) ...[
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
    );
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
                          'Par : ${req.beneficiaryPersonName ?? (req.createdById == controller.currentUserId ? (StorageService.instance.fullName ?? "Moi") : "Collaborateur")}',
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
