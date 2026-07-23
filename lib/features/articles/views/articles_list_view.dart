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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => Get.bottomSheet(
              ArticleFilterSheet(controller: controller),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              onChanged: controller.search,
              decoration: const InputDecoration(
                hintText: 'Rechercher un article...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
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
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        return ArticleCard(article: articles[index]);
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
