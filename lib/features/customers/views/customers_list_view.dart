import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/view_status.dart';
import '../controllers/customers_controller.dart';
import '../widgets/customer_card.dart';

class CustomersListView extends GetView<CustomersController> {
  const CustomersListView({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        controller.loadMore();
      }
    });

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          Obx(() {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.filteredCustomers.length} Client(s)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // Search input field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: TextField(
              onChanged: controller.search,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, activité ou téléphone...',
                prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                isDense: true,
              ),
            ),
          ),

          Expanded(
            child: Obx(() {
              switch (controller.status.value) {
                case ViewStatus.initial:
                case ViewStatus.loading:
                  return const Center(child: CircularProgressIndicator());
                case ViewStatus.error:
                  return _ErrorState(
                    message:
                        controller.errorMessage.value ?? 'Une erreur est survenue.',
                    onRetry: controller.fetchCustomers,
                  );
                case ViewStatus.empty:
                  return RefreshIndicator(
                    onRefresh: controller.refreshCustomers,
                    child: ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('Aucun client trouvé.')),
                      ],
                    ),
                  );
                case ViewStatus.success:
                  final customers = controller.displayedCustomers;
                  return RefreshIndicator(
                    onRefresh: controller.refreshCustomers,
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: customers.length + (controller.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= customers.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        final customer = customers[index];
                        return CustomerCard(customer: customer);
                      },
                    ),
                  );
              }
            }),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
