import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/view_status.dart';
import '../controllers/articles_controller.dart';
import '../widgets/article_card.dart';
import '../widgets/article_filter_sheet.dart';

class ArticlesListView extends GetView<ArticlesController> {
  const ArticlesListView({super.key});

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
        title: const Text('Articles'),
        actions: [
          Obx(() {
            final activeCount = controller.activeFiltersCount;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded),
                  tooltip: 'Filtres',
                  onPressed: () => Get.bottomSheet(
                    ArticleFilterSheet(controller: controller),
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),
                ),
                if (activeCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$activeCount',
                        style: TextStyle(
                          color: colorScheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: TextField(
              onChanged: controller.search,
              decoration: InputDecoration(
                hintText: 'Rechercher un article ou référence...',
                prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                isDense: true,
              ),
            ),
          ),

          // Active filter indicator bar
          Obx(() {
            if (controller.activeFiltersCount == 0) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_alt_outlined, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${controller.activeFiltersCount} filtre(s) actif(s)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: controller.clearFilters,
                    child: Text(
                      'Effacer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          Expanded(
            child: Obx(() {
              switch (controller.status.value) {
                case ViewStatus.initial:
                case ViewStatus.loading:
                  return const Center(child: CircularProgressIndicator());
                case ViewStatus.error:
                  return _ErrorState(
                    message: controller.errorMessage.value ?? 'Une erreur est survenue.',
                    onRetry: controller.fetchArticles,
                  );
                case ViewStatus.empty:
                  return RefreshIndicator(
                    onRefresh: controller.refreshArticles,
                    child: ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('Aucun article trouvé.')),
                      ],
                    ),
                  );
                case ViewStatus.success:
                  final articles = controller.displayedArticles;
                  return RefreshIndicator(
                    onRefresh: controller.refreshArticles,
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: articles.length + (controller.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= articles.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        final article = articles[index];
                        final articleId = article.id;

                        return Obx(() {
                          final stockSummary = articleId != null
                              ? controller.stockMap[articleId]
                              : null;
                          final isExpanded = articleId != null &&
                              controller.expandedArticleId.value == articleId;

                          return ArticleCard(
                            article: article,
                            stockSummary: stockSummary,
                            isExpanded: isExpanded,
                            onToggleExpand: articleId != null
                                ? () => controller.toggleExpandArticle(articleId)
                                : null,
                          );
                        });
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
