import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../models/treasury_dto.dart';

/// Executive Caisse & Treasury Cards widget for WoodApp Mobile Admin View.
/// Replicates & displays the two primary treasury cards from `acya-app/elance-app.ui/src/app/accounting/treasury/page.tsx`:
/// 1. Caisse Principale (Solde du coffre central)
/// 2. Caisse par Point de Vente (Solde total des boutiques + liste déroulante interactive par point de vente)
class CaisseTreasuryCardsWidget extends StatefulWidget {
  final HomeController controller;

  const CaisseTreasuryCardsWidget({
    super.key,
    required this.controller,
  });

  @override
  State<CaisseTreasuryCardsWidget> createState() => _CaisseTreasuryCardsWidgetState();
}

class _CaisseTreasuryCardsWidgetState extends State<CaisseTreasuryCardsWidget> {
  bool _isSitesExpanded = false;

  /// Formats currency values in Tunisian Dinar (TND) format (e.g. 12 500,000 DT)
  String _formatCurrency(double val) {
    final parts = val.toStringAsFixed(3).split('.');
    final integerPart = parts[0].replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ' ');
    return '$integerPart,${parts[1]} DT';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final mainCaisseBalance = widget.controller.caissePrincipaleBalance.value;
      final siteBalances = widget.controller.siteCaisseBalances;
      final totalSitesBalance = widget.controller.totalSitesCaisseBalance;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 18,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trésorerie Caisses (Admin)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'ÉLANCÉ SYNC',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD97706),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- CARD 1: CAISSE PRINCIPALE ---
          _buildCaissePrincipaleCard(
            context,
            theme: theme,
            colorScheme: colorScheme,
            isDark: isDark,
            balance: mainCaisseBalance,
          ),

          const SizedBox(height: 14),

          // --- CARD 2: CAISSE PAR POINT DE VENTE ---
          _buildCaissePointDeVenteCard(
            context,
            theme: theme,
            colorScheme: colorScheme,
            isDark: isDark,
            totalBalance: totalSitesBalance,
            sites: siteBalances,
          ),
        ],
      );
    });
  }

  /// Builds Card 1: Caisse Principale (Central Vault Cash Card)
  Widget _buildCaissePrincipaleCard(
    BuildContext context, {
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDark,
    required double balance,
  }) {
    const amberColor = Color(0xFFD97706);
    const amberBg = Color(0xFFFEF3C7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: amberColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: amberColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: amberBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      color: amberColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COFFRE CENTRAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: amberColor.withValues(alpha: 0.9),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Caisse Principale',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: amberBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Principale',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: amberColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Fonds disponibles dans le coffre central :',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCurrency(balance),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds Card 2: Caisse par Point de Vente (Store Cash Card with expandable list)
  Widget _buildCaissePointDeVenteCard(
    BuildContext context, {
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDark,
    required double totalBalance,
    required List<SiteCaisseBalanceDto> sites,
  }) {
    final primaryColor = colorScheme.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BOUTIQUES & MAGASINS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryColor.withValues(alpha: 0.9),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Caisse par Point de Vente',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7), // Light Emerald
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'En Direct',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Total des liquidités dans les boutiques :',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatCurrency(totalBalance),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider before breakdown accordion button
          Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),

          // Expandable Toggle Button
          InkWell(
            onTap: () {
              setState(() {
                _isSitesExpanded = !_isSitesExpanded;
              });
            },
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Détail des ${sites.length} Points de Vente',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    _isSitesExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expandable Site List Items
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                if (sites.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Aucun point de vente répertorié',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sites.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                    itemBuilder: (context, index) {
                      final site = sites[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  site.salesSiteName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID Site: ${site.salesSiteId}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                _formatCurrency(site.currentBalance),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: primaryColor,
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
            crossFadeState:
                _isSitesExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}
