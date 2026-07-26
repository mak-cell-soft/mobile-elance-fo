import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/storage/storage_service.dart';
import '../controllers/settings_controller.dart';
import '../widgets/daily_ceiling_tab_view.dart';
import '../widgets/workflow_automation_tab_view.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    final colorScheme = Theme.of(context).colorScheme;

    // Admin Role Access Guard
    if (!storage.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Paramètres')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 56,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Accès Restreint',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La configuration du système est réservée aux administrateurs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paramètres & Configuration'),
          bottom: TabBar(
            labelColor: colorScheme.primary,
            indicatorColor: colorScheme.primary,
            tabs: const [
              Tab(
                icon: Icon(Icons.trending_up_rounded, size: 20),
                text: 'Plafond Journalier',
              ),
              Tab(
                icon: Icon(Icons.auto_awesome_rounded, size: 20),
                text: 'Flux & Automations',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DailyCeilingTabView(controller: controller),
            WorkflowAutomationTabView(controller: controller),
          ],
        ),
      ),
    );
  }
}
