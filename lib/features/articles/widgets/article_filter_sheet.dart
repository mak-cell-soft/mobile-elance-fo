import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/articles_controller.dart';

class ArticleFilterSheet extends StatelessWidget {
  final ArticlesController controller;

  const ArticleFilterSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Obx(() {
          final categories = controller.categories;
          final selectedCatId = controller.selectedCategoryId.value;
          final subCategories = controller.availableSubCategories;
          final selectedSubCatId = controller.selectedSubCategoryId.value;
          final woodFilter = controller.woodOnlyFilter.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_alt_outlined, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Filtres des Articles',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Catégorie Dropdown
              Text(
                'Catégorie',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: selectedCatId,
                    isExpanded: true,
                    hint: const Text('Toutes les catégories'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'Toutes les catégories',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...categories.map((cat) {
                        return DropdownMenuItem<int?>(
                          value: cat.id,
                          child: Text(cat.label),
                        );
                      }),
                    ],
                    onChanged: (val) => controller.filterByCategory(val),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sous-Catégorie Dropdown
              Text(
                'Sous-Catégorie',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: selectedCatId == null || subCategories.isEmpty
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                      : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: selectedCatId == null || subCategories.isEmpty
                      ? colorScheme.surfaceContainerLowest
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: selectedSubCatId,
                    isExpanded: true,
                    disabledHint: Text(
                      selectedCatId == null
                          ? 'Sélectionnez d\'abord une catégorie'
                          : 'Aucune sous-catégorie disponible',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    hint: const Text('Toutes les sous-catégories'),
                    items: selectedCatId == null || subCategories.isEmpty
                        ? null
                        : [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                'Toutes les sous-catégories',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...subCategories.map((sub) {
                              return DropdownMenuItem<int?>(
                                value: sub.id,
                                child: Text(sub.label),
                              );
                            }),
                          ],
                    onChanged: (val) => controller.filterBySubCategory(val),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Type d'article Chips (Tous / Bois / Non Bois)
              Text(
                'Type d\'article',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Tous'),
                    selected: woodFilter == null,
                    onSelected: (_) => controller.filterByWood(null),
                  ),
                  ChoiceChip(
                    label: const Text('Bois uniquement'),
                    selected: woodFilter == true,
                    onSelected: (_) => controller.filterByWood(true),
                  ),
                  ChoiceChip(
                    label: const Text('Non bois'),
                    selected: woodFilter == false,
                    onSelected: (_) => controller.filterByWood(false),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Result Count & Action Buttons
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${controller.filteredArticles.length} Article(s)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (controller.activeFiltersCount > 0)
                    TextButton.icon(
                      onPressed: () => controller.clearFilters(),
                      icon: const Icon(Icons.clear_all_rounded, size: 18),
                      label: const Text('Réinitialiser'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Afficher'),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}
