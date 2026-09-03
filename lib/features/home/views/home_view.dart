import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../core/config/tenant_build_config.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/theme_service.dart';
import '../../../core/utils/view_status.dart';
import '../../../routes/app_routes.dart';
import '../../profile/widgets/profile_sheet.dart';
import '../controllers/home_controller.dart';
import '../widgets/analytics_filter_bar_widget.dart';
import '../widgets/caisse_treasury_cards_widget.dart';
import '../widgets/kpi_card_widget.dart';
import '../widgets/receivables_chart_widget.dart';
import '../widgets/supplier_chart_widget.dart';

/// Executive Home Dashboard View following modern Stitch UI principles.
/// Features a branded AppBar, welcome banner with user role highlight,
/// admin-only executive analytics cards & charts, and interactive feature navigation modules.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: SvgPicture.asset(
              TenantBuildConfig.logoPath,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(storage.enterpriseName ?? TenantBuildConfig.appName),
        actions: [
          Obx(() {
            final isDark = ThemeService.instance.isDarkMode;
            return IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 22,
              ),
              tooltip: isDark ? 'Passer en Mode Clair' : 'Passer en Mode Sombre',
              onPressed: () => ThemeService.instance.toggleTheme(),
            );
          }),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 24),
            tooltip: 'Notifications',
            onPressed: () => Get.toNamed(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, size: 28),
            tooltip: 'Mon Profil',
            onPressed: () => ProfileSheet.show(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Unified refresh for all sections
          await controller.loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HERO WELCOME BANNER ---
              _buildHeroBanner(context, storage, colorScheme),

              // --- 2. TREASURY & ANALYTICS SECTIONS (Admin Only) ---
              if (storage.isAdmin) ...[
                const SizedBox(height: 24),

                // Caisse & Treasury Cards (Caisse Principale & Caisse par Point de Vente)
                _buildTreasurySection(context, colorScheme),

                const SizedBox(height: 24),

                // Executive Analytics Dashboard
                _buildAnalyticsSection(context, colorScheme),
              ],

              const SizedBox(height: 28),

              // --- 3. MODULES & OUTILS SECTION ---
              Text(
                'Modules & Outils',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 14),

              // Module Card: Catalogue des Articles
              _buildModuleCard(
                context,
                title: 'Catalogue des Articles',
                description: 'Consulter, filtrer et rechercher les articles',
                icon: Icons.inventory_2_rounded,
                iconColor: colorScheme.primary,
                backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
                onTap: () => Get.toNamed(AppRoutes.articles),
              ),

              const SizedBox(height: 12),

              // Module Card: Gestion des Clients
              _buildModuleCard(
                context,
                title: 'Gestion des Clients',
                description: 'Liste des clients, contacts et soldes actuels',
                icon: Icons.people_alt_rounded,
                iconColor: colorScheme.secondary,
                backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                onTap: () => Get.toNamed(AppRoutes.customers),
              ),

              // Module Card: Chantiers (Général, Suivi & Caisse)
              if (storage.hasChantierModule) ...[
                const SizedBox(height: 12),
                _buildModuleCard(
                  context,
                  title: 'Gestion des Chantiers',
                  description: 'Général, suivi d\'avancement & caisse terrain',
                  icon: Icons.construction_rounded,
                  iconColor: const Color(0xFF2563EB),
                  backgroundColor: const Color(0xFFEFF6FF),
                  onTap: () => Get.toNamed(AppRoutes.chantiers),
                ),
              ],

              // Module Card: Paramètres Système (Admin Only)
              if (storage.isAdmin) ...[
                const SizedBox(height: 12),
                _buildModuleCard(
                  context,
                  title: 'Paramètres Système',
                  description: 'Plafonds journaliers & automations de facturation',
                  icon: Icons.settings_suggest_rounded,
                  iconColor: colorScheme.tertiary,
                  backgroundColor: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                  onTap: () => Get.toNamed(AppRoutes.settings),
                  badgeLabel: 'ADMIN',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the top Hero Banner displaying greeting, role badge, and profile trigger.
  Widget _buildHeroBanner(
      BuildContext context, StorageService storage, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Tenant Slug Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  storage.tenantSlug?.toUpperCase() ?? 'ERP',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // User Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B), // Amber Gold
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      storage.translatedRole,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.verified_user_rounded,
                  color: colorScheme.onPrimary.withValues(alpha: 0.9),
                  size: 22,
                ),
                onPressed: () => ProfileSheet.show(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Bonjour, ${storage.fullName ?? 'Utilisateur'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bienvenue sur votre espace de gestion ERP.',
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          if (storage.defaultSite != null &&
              storage.defaultSite!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.onPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storefront_rounded,
                    size: 15,
                    color: colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Site de vente : ${storage.defaultSite}',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the Treasury Section containing Caisse Principale & Caisse par Point de Vente Cards.
  /// Decoupled from Admin Analytics so failure in one does not hide the other.
  Widget _buildTreasurySection(BuildContext context, ColorScheme colorScheme) {
    return Obx(() {
      if (controller.treasuryStatus.value == ViewStatus.loading &&
          controller.caissePrincipaleBalance.value == 0.0) {
        return Container(
          height: 120,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.treasuryStatus.value == ViewStatus.error &&
          controller.caissePrincipaleBalance.value == 0.0) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.treasuryErrorMessage.value ?? 'Erreur lors du chargement de la trésorerie',
                  style: TextStyle(color: colorScheme.error, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () => controller.loadTreasuryData(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        );
      }

      return CaisseTreasuryCardsWidget(controller: controller);
    });
  }

  /// Builds the Analytics Section containing Year & Month selector, KPI Cards & Financial Charts.
  Widget _buildAnalyticsSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row with Refresh action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aperçu Analytique',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              tooltip: 'Actualiser les données',
              onPressed: () => controller.loadAdminAnalytics(),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Year & Month Selection Filter Bar (matching Next.js fo-acya-app/elance-app.ui)
        AnalyticsFilterBarWidget(controller: controller),
        const SizedBox(height: 16),

        Obx(() {
          if (controller.status.value == ViewStatus.loading) {
            return Container(
              height: 140,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (controller.status.value == ViewStatus.error) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.errorMessage.value ?? 'Erreur lors du chargement',
                      style: TextStyle(color: colorScheme.error, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.loadAdminAnalytics(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Cards Grid Row: CA (Mois / Année) & CA Achat (Mois / Année)
              Row(
                children: [
                  Expanded(
                    child: KpiCardWidget(
                      title: controller.salesKpiTitle,
                      value: controller.monthlySales.value,
                      icon: Icons.trending_up_rounded,
                      accentColor: const Color(0xFF10B981), // Emerald
                      periodLabel: controller.salesPeriodLabel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiCardWidget(
                      title: controller.purchasesKpiTitle,
                      value: controller.monthlyPurchaseTtc.value,
                      icon: Icons.shopping_bag_outlined,
                      accentColor: const Color(0xFFD97706), // Amber
                      periodLabel: controller.purchasesPeriodLabel,
                      isPurchase: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Chart 1: Achats vs Règlements par Fournisseur
              SupplierChartWidget(
                dataPoints: controller.supplierChartPoints,
              ),

              const SizedBox(height: 18),

              // Chart 2: Suivi des Créances Clients
              ReceivablesChartWidget(
                receivables: controller.filteredReceivables,
                searchQuery: controller.receivablesSearchQuery.value,
                onSearchChanged: (val) => controller.receivablesSearchQuery.value = val,
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Builds reusable feature navigation cards for modules.
  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
    String? badgeLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (badgeLabel != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeLabel,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
