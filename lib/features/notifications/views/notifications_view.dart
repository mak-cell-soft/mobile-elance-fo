import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/view_status.dart';
import '../controllers/notification_controller.dart';
import '../models/app_notification.dart';
import '../models/notification_type.dart';
import '../models/stock_alert.dart';
import '../models/transfer_notification.dart';

/// Notification Center View built with Arbor Industrial design principles.
/// Features tabbed notifications (Inter-site transfers, System notifications, Stock alerts)
/// with severity badges, quick actions, and pull-to-refresh capabilities.
class NotificationsView extends GetView<NotificationController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
            children: [
              _buildTransfersTab(context, colorScheme),
              _buildSystemTab(context, colorScheme),
              _buildStockTab(context, colorScheme),
            ],
          );
        }),
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      Text(
                        item.transferRef,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Site Origine: #${item.originSite} → Dest: #${item.destinationSiteId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => controller.dismiss(item.id, isTransfer: true),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.exitDocNumber.isNotEmpty)
                  Text(
                    'Doc Sortie: ${item.exitDocNumber}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                if (item.itemsCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.itemsCount} article(s)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
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

    return Card(
      child: InkWell(
        onTap: () {
          if (!item.isRead) controller.markAsRead(item.id);
          if (isCaisse && chantierId != null) {
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
                    if (isCaisse && chantierId != null) ...[
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                  Text(
                    item.designation,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Réf: ${item.articleCode}${item.siteName != null ? ' • ${item.siteName}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.currentStock.toStringAsFixed(0)} en stock',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Min: ${item.minThreshold.toStringAsFixed(0)}',
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
