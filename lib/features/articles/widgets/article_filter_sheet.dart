import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/articles_controller.dart';

class ArticleFilterSheet extends StatelessWidget {
  final ArticlesController controller;

  const ArticleFilterSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtrer', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Text('Type', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Tous'),
                    selected: controller.woodOnlyFilter.value == null,
                    onSelected: (_) => controller.filterByWood(null),
                  ),
                  ChoiceChip(
                    label: const Text('Bois'),
                    selected: controller.woodOnlyFilter.value == true,
                    onSelected: (_) => controller.filterByWood(true),
                  ),
                  ChoiceChip(
                    label: const Text('Non bois'),
                    selected: controller.woodOnlyFilter.value == false,
                    onSelected: (_) => controller.filterByWood(false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Catégorie', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Toutes'),
                    selected: controller.selectedCategoryId.value == null,
                    onSelected: (_) => controller.filterByCategory(null),
                  ),
                  ...controller.availableCategories.map(
                    (category) => ChoiceChip(
                      label: Text(category.label),
                      selected: controller.selectedCategoryId.value == category.id,
                      onSelected: (_) => controller.filterByCategory(category.id),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    controller.clearFilters();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Réinitialiser'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
