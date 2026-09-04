import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chantier_detail.dart';

/// Onglet Suivi: displays timeline progress entries, milestones,
/// and active alerts / vigilance items.
class SuiviTabWidget extends StatelessWidget {
  final ChantierDetail detail;
  final List<ChantierProgressEntry> progressEntries;
  final List<ChantierAlert> alerts;

  const SuiviTabWidget({
    super.key,
    required this.detail,
    required this.progressEntries,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

    // If progressEntries list from API is empty, provide fallback milestones based on startDate
    final entries = progressEntries.isNotEmpty
        ? progressEntries
        : _buildFallbackTimeline(detail);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Alertes & Vigilance Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: const Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Text(
                      'Alertes & Vigilance',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (alerts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 18, color: Color(0xFF16A34A)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Aucune alerte critique en cours sur ce chantier.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: alerts.map((alert) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: alert.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: alert.borderColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              alert.isCritical
                                  ? Icons.error_outline_rounded
                                  : Icons.info_outline_rounded,
                              size: 18,
                              color: alert.badgeColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alert.message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: alert.badgeColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateFormat.format(alert.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: alert.badgeColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Timeline du cycle de vie du chantier
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timeline_rounded,
                        size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Cycle de vie du chantier',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Vertical Timeline
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final item = entries[index];
                    final isLast = index == entries.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Node Icon & Connecting Line
                          Column(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: item.isDone
                                      ? const Color(0xFF10B981)
                                      : colorScheme.surfaceContainerHighest,
                                  border: Border.all(
                                    color: item.isDone
                                        ? const Color(0xFF10B981)
                                        : colorScheme.outlineVariant,
                                    width: 2,
                                  ),
                                ),
                                child: item.isDone
                                    ? const Icon(
                                        Icons.check,
                                        size: 13,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Entry Details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        dateFormat.format(item.entryDate),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: item.isDone
                                              ? const Color(0xFFECFDF5)
                                              : colorScheme.surfaceContainerHighest,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.isDone ? 'Terminé' : 'En attente',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: item.isDone
                                                ? const Color(0xFF047857)
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (item.description != null &&
                                      item.description!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.description!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Generates meaningful milestones if no backend progress entries were yet logged
  List<ChantierProgressEntry> _buildFallbackTimeline(ChantierDetail site) {
    final start = site.startDate ?? DateTime.now();
    return [
      ChantierProgressEntry(
        id: 1,
        chantierId: site.id,
        title: 'Ouverture de chantier',
        description: "Installation de chantier & clôture périmétrique terminées.",
        entryType: 'Milestone',
        entryStatus: 'Done',
        entryDate: start,
        recordedById: 1,
      ),
      ChantierProgressEntry(
        id: 2,
        chantierId: site.id,
        title: 'Fondations & Gros Œuvre',
        description: "Validation par le bureau de contrôle & terrassement.",
        entryType: 'Milestone',
        entryStatus: site.progressPct >= 30 ? 'Done' : 'Pending',
        entryDate: start.add(const Duration(days: 20)),
        recordedById: 1,
      ),
      ChantierProgressEntry(
        id: 3,
        chantierId: site.id,
        title: 'Second Œuvre & Finitions',
        description: "Plomberie, menuiserie aluminium & bois, électricité.",
        entryType: 'Milestone',
        entryStatus: site.progressPct >= 80 ? 'Done' : 'Pending',
        entryDate: start.add(const Duration(days: 60)),
        recordedById: 1,
      ),
      ChantierProgressEntry(
        id: 4,
        chantierId: site.id,
        title: 'Livraison & Réception provisoire',
        description: "Visite de conformité finale avec l'architecte.",
        entryType: 'Milestone',
        entryStatus: site.progressPct >= 100 ? 'Done' : 'Pending',
        entryDate: site.plannedEndDate ?? start.add(const Duration(days: 90)),
        recordedById: 1,
      ),
    ];
  }
}
