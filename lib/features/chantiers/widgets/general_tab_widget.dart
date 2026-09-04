import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chantier_detail.dart';

/// Onglet Général: displays core description, internal notes, schedule,
/// location, and architect/project manager metadata.
class GeneralTabWidget extends StatelessWidget {
  final ChantierDetail detail;

  const GeneralTabWidget({
    super.key,
    required this.detail,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non définie';
    try {
      return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
    } catch (_) {
      try {
        return DateFormat('dd/MM/yyyy').format(date);
      } catch (_) {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. À propos du projet Card
          _buildCard(
            context,
            title: 'À propos du projet',
            icon: Icons.info_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.description != null && detail.description!.isNotEmpty
                      ? detail.description!
                      : 'Aucune description fournie pour ce chantier. Ce projet consiste en la réalisation des travaux selon les plans approuvés.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),

                // Note interne highlight
                if (detail.internalNote != null && detail.internalNote!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // Soft Blue
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                        left: BorderSide(color: Color(0xFF2563EB), width: 4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.sticky_note_2_outlined,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'NOTE INTERNE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          detail.internalNote!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Échéancier Card
          _buildCard(
            context,
            title: 'Échéancier & Calendrier',
            icon: Icons.calendar_today_rounded,
            child: Column(
              children: [
                _buildScheduleRow(
                  label: 'Date de début',
                  dateStr: _formatDate(detail.startDate),
                  icon: Icons.play_arrow_rounded,
                  iconColor: const Color(0xFF10B981),
                ),
                const Divider(height: 20),
                _buildScheduleRow(
                  label: 'Fin estimée / prévue',
                  dateStr: _formatDate(detail.plannedEndDate),
                  icon: Icons.flag_rounded,
                  iconColor: const Color(0xFF2563EB),
                ),
                if (detail.actualEndDate != null) ...[
                  const Divider(height: 20),
                  _buildScheduleRow(
                    label: 'Date de fin réelle',
                    dateStr: _formatDate(detail.actualEndDate),
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: const Color(0xFF639922),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Architecte & Conduite de Travaux
          _buildCard(
            context,
            title: 'Intervenants & Direction',
            icon: Icons.badge_outlined,
            child: Column(
              children: [
                _buildPersonTile(
                  role: 'Architecte',
                  name: detail.architectName ?? 'Non assigné',
                  icon: Icons.architecture_rounded,
                  color: const Color(0xFF7C3AED),
                ),
                const Divider(height: 16),
                _buildPersonTile(
                  role: 'Chef de Chantier / Conducteur',
                  name: detail.projectManagerName ?? 'Non assigné',
                  icon: Icons.engineering_rounded,
                  color: const Color(0xFFD97706),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Localisation & Gouvernorat
          _buildCard(
            context,
            title: 'Localisation',
            icon: Icons.map_rounded,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.pin_drop_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.location ?? 'Adresse non spécifiée',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (detail.gouvernorate != null && detail.gouvernorate!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          detail.gouvernorate!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
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
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildScheduleRow({
    required String label,
    required String dateStr,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          dateStr,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonTile({
    required String role,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
