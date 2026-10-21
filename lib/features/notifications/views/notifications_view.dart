import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../controllers/notification_controller.dart';
import '../models/app_notification.dart';
import '../models/notification_type.dart';
import '../models/stock_alert.dart';
import '../models/transfer_notification.dart';

/// Notification Center View built with Arbor Industrial design principles.
/// Features tabbed notifications (Inter-site transfers, System notifications, Stock alerts)
/// with severity badges, quick actions, and pull-to-refresh capabilities.
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> with SingleTickerProviderStateMixin {
  late final NotificationController controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<NotificationController>();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Reliable refresh whenever the Notifications screen is opened or revisited
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.onScreenOpened();
      }
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging && _tabController.index == 0) {
      // User switched specifically to Transfers tab
      controller.refreshTransfers();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre de Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Actualiser',
            onPressed: () => controller.loadAll(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'read_all') {
                controller.markAllAsRead();
              } else if (value == 'retry') {
                controller.retryFailed();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'read_all',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Tout marquer comme lu'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'retry',
                child: Row(
                  children: [
                    Icon(Icons.replay_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Renvoyer les échecs'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          indicatorColor: colorScheme.primary,
          isScrollable: false,
          tabs: [
              Obx(() => Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Transferts'),
                        if (controller.transferNotifications.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _buildCountBadge(
                            context,
                            controller.transferNotifications.length,
                            colorScheme.secondaryContainer,
                            colorScheme.onSecondaryContainer,
                          ),
                        ],
                      ],
                    ),
                  )),
              Obx(() => Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Système'),
                        if (controller.systemNotifications.where((n) => !n.isRead).isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _buildCountBadge(
                            context,
                            controller.systemNotifications.where((n) => !n.isRead).length,
                            colorScheme.primaryContainer,
                            colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ],
                    ),
                  )),
              Obx(() => Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Stock'),
                        if (controller.stockAlerts.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _buildCountBadge(
                            context,
                            controller.stockAlerts.length,
                            colorScheme.errorContainer,
                            colorScheme.onErrorContainer,
                          ),
                        ],
                      ],
                    ),
                  )),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.status.value == ViewStatus.loading &&
              controller.systemNotifications.isEmpty &&
              controller.transferNotifications.isEmpty &&
              controller.stockAlerts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.status.value == ViewStatus.error &&
              controller.systemNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
                  const SizedBox(height: 12),
                  Text(
                    controller.errorMessage.value ?? 'Erreur lors du chargement',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadAll(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTransfersTab(context, colorScheme),
              _buildSystemTab(context, colorScheme),
              _buildStockTab(context, colorScheme),
            ],
          );
        }),
      );
  }

  Widget _buildCountBadge(
      BuildContext context, int count, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds the Inter-Site Transfers Notification tab.
  Widget _buildTransfersTab(BuildContext context, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: () => controller.loadAll(),
      child: controller.transferNotifications.isEmpty
          ? _buildEmptyState(
              context,
              icon: Icons.local_shipping_outlined,
              title: 'Aucun transfert en attente',
              message: 'Toutes les expéditions inter-sites sont à jour.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.transferNotifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = controller.transferNotifications[index];
                return _buildTransferCard(context, item, colorScheme);
              },
            ),
    );
  }

  Widget _buildTransferCard(
      BuildContext context, TransferNotification item, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon, Reference, Dismiss Action
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.sync_alt_rounded, color: colorScheme.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prominent Transfer Reference
                      Text(
                        item.transferRef,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                      ),
                      const SizedBox(height: 4),
                      // Human-readable Origin & Destination (strictly no #0)
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.displayOriginSite,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              item.displayDestinationSite,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Supprimer la notification',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => controller.dismiss(item.id, isTransfer: true),
                ),
              ],
            ),
            const Divider(height: 20),
            // Middle Row: Doc Sortie and Items Count Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.exitDocNumber.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Doc Sortie: ${item.exitDocNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.itemsCount} article${item.itemsCount > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            // Expandable Section: Transferred Article Line Items
            const SizedBox(height: 8),
            Obx(() {
              final isExpanded = controller.expandedTransferIds.contains(item.id);
              final isLoading = controller.loadingTransferDetails[item.id] == true;
              final errorMsg = controller.errorTransferDetails[item.id];
              final articles = controller.transferDetails[item.id] ?? item.inlineArticles ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => controller.toggleTransferExpanded(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isExpanded ? 'Masquer le détail des articles' : 'Voir les articles transférés',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    if (isLoading)
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Chargement des articles...',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    else if (errorMsg != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, size: 16, color: colorScheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMsg,
                                style: TextStyle(fontSize: 12, color: colorScheme.error),
                              ),
                            ),
                            TextButton(
                              onPressed: () => controller.loadTransferDetails(item),
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              child: const Text('Réessayer', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      )
                    else if (articles.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        alignment: Alignment.center,
                        child: Text(
                          'Aucun article détaillé disponible pour ce transfert.',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: articles.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                          ),
                          itemBuilder: (context, idx) {
                            final art = articles[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Article Reference & Description
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          art.articleReference.isNotEmpty
                                              ? art.articleReference
                                              : 'Article sans référence',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (art.description.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            art.description,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        if (art.packageReference != null && art.packageReference!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Paquet: ${art.packageReference}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Quantity & Unit
                                  Text(
                                    '${art.quantity.toStringAsFixed(art.quantity % 1 == 0 ? 0 : 2)}${art.unit != null && art.unit!.isNotEmpty ? ' ${art.unit}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Builds the System Notifications tab.
  Widget _buildSystemTab(BuildContext context, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: () => controller.loadAll(),
      child: controller.systemNotifications.isEmpty
          ? _buildEmptyState(
              context,
              icon: Icons.notifications_none_rounded,
              title: 'Aucune notification système',
              message: 'Vous êtes à jour !',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.systemNotifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = controller.systemNotifications[index];
                return _buildSystemNotificationCard(context, item, colorScheme);
              },
            ),
    );
  }

  Widget _buildSystemNotificationCard(
      BuildContext context, AppNotification item, ColorScheme colorScheme) {
    final severityColor = _getSeverityColor(item.type, colorScheme);
    final isCaisse = item.isCaisseRequest;
    final chantierId = item.chantierIdFromAction;
    final hasChantierModule = StorageService.instance.hasChantierModule;

    return Card(
      child: InkWell(
        onTap: () {
          if (!item.isRead) controller.markAsRead(item.id);
          if (isCaisse && chantierId != null && hasChantierModule) {
            controller.navigateToChantierCaisse(chantierId);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCaisse
                      ? const Color(0xFFD97706).withValues(alpha: 0.15)
                      : severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCaisse ? Icons.account_balance_wallet_rounded : _getSeverityIcon(item.type),
                  color: isCaisse ? const Color(0xFFD97706) : severityColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight:
                                      item.isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (isCaisse && chantierId != null && hasChantierModule) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (!item.isRead) controller.markAsRead(item.id);
                            controller.navigateToChantierCaisse(chantierId);
                          },
                          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                          label: const Text('Examiner la caisse', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD97706),
                            side: const BorderSide(color: Color(0xFFD97706)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the Stock Threshold Alerts tab.
  Widget _buildStockTab(BuildContext context, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: () => controller.loadAll(),
      child: controller.stockAlerts.isEmpty
          ? _buildEmptyState(
              context,
              icon: Icons.inventory_rounded,
              title: 'Aucune alerte de stock',
              message: 'Tous les niveaux de stock sont optimaux.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.stockAlerts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = controller.stockAlerts[index];
                return _buildStockAlertCard(context, item, colorScheme);
              },
            ),
    );
  }

  Widget _buildStockAlertCard(
      BuildContext context, StockAlert item, ColorScheme colorScheme) {
    final qtyUnit = item.unit != null && item.unit!.trim().isNotEmpty ? ' ${item.unit}' : '';
    final currentStr = item.currentStock % 1 == 0 ? item.currentStock.toInt().toString() : item.currentStock.toStringAsFixed(2);
    final minStr = item.minThreshold % 1 == 0 ? item.minThreshold.toInt().toString() : item.minThreshold.toStringAsFixed(2);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Prominent Article Reference
                  Text(
                    item.articleReference.isNotEmpty ? item.articleReference : item.designation,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                  ),
                  const SizedBox(height: 3),
                  // 2. Clear Article Description (when available and distinct)
                  if (item.description.trim().isNotEmpty && item.description != item.articleReference)
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  // 3. Packaging reference badge & site metadata
                  Row(
                    children: [
                      if (item.packageReference != null && item.packageReference!.trim().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Paquet: ${item.packageReference}',
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (item.siteName != null && item.siteName!.isNotEmpty) const SizedBox(width: 6),
                      ],
                      if (item.siteName != null && item.siteName!.isNotEmpty)
                        Text(
                          item.siteName!,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Current Stock & Minimum Threshold
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currentStr$qtyUnit en stock',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Min: $minStr$qtyUnit',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(NotificationType type, ColorScheme colorScheme) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF10B981);
      case NotificationType.warning:
        return const Color(0xFFF59E0B);
      case NotificationType.error:
        return colorScheme.error;
      case NotificationType.info:
        return colorScheme.primary;
    }
  }

  IconData _getSeverityIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_outline_rounded;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.error:
        return Icons.error_outline_rounded;
      case NotificationType.info:
        return Icons.info_outline_rounded;
    }
  }
}
