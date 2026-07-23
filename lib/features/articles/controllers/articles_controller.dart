import 'package:get/get.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/view_status.dart';
import '../models/article.dart';
import '../models/category_ref.dart';
import '../services/article_service.dart';

/// Handles the full article list flow. The backend has no server-side
/// pagination/search/filter (GET /api/article returns everything), so all
/// three are implemented client-side over the single fetched list.
class ArticlesController extends GetxController {
  static const int pageSize = 20;

  final ArticleService _service = ArticleService();

  final status = ViewStatus.initial.obs;
  final errorMessage = RxnString();

  final _allArticles = <Article>[].obs;
  final filteredArticles = <Article>[].obs;
  final visibleCount = pageSize.obs;

  final searchQuery = ''.obs;
  final selectedCategoryId = RxnInt();
  final woodOnlyFilter = RxnBool();

  @override
  void onInit() {
    super.onInit();
    fetchArticles();

    debounce(searchQuery, (_) => _applyFilters(),
        time: const Duration(milliseconds: 300));
    ever(selectedCategoryId, (_) => _applyFilters());
    ever(woodOnlyFilter, (_) => _applyFilters());
  }

  List<CategoryRef> get availableCategories {
    final seen = <int, CategoryRef>{};
    for (final article in _allArticles) {
      final category = article.category;
      if (category?.id != null) {
        seen[category!.id!] = category;
      }
    }
    return seen.values.toList();
  }

  List<Article> get displayedArticles =>
      filteredArticles.take(visibleCount.value).toList();

  bool get hasMore => visibleCount.value < filteredArticles.length;

  Future<void> fetchArticles() async {
    status.value = ViewStatus.loading;
    errorMessage.value = null;

    try {
      final result = await _service.fetchAll();
      _allArticles.assignAll(result);
      _applyFilters();
    } on ApiException catch (e) {
      status.value = ViewStatus.error;
      errorMessage.value = e.message;
    }
  }

  Future<void> refreshArticles() => fetchArticles();

  void loadMore() {
    if (!hasMore) return;
    visibleCount.value =
        (visibleCount.value + pageSize).clamp(0, filteredArticles.length);
  }

  void search(String query) {
    searchQuery.value = query;
  }

  void filterByCategory(int? categoryId) {
    selectedCategoryId.value = categoryId;
  }

  void filterByWood(bool? woodOnly) {
    woodOnlyFilter.value = woodOnly;
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedCategoryId.value = null;
    woodOnlyFilter.value = null;
  }

  void _applyFilters() {
    final query = searchQuery.value.trim().toLowerCase();
    final categoryId = selectedCategoryId.value;
    final woodOnly = woodOnlyFilter.value;

    final result = _allArticles.where((article) {
      if (query.isNotEmpty) {
        final matchesReference =
            article.reference?.toLowerCase().contains(query) ?? false;
        final matchesDescription =
            article.description?.toLowerCase().contains(query) ?? false;
        if (!matchesReference && !matchesDescription) return false;
      }

      if (categoryId != null && article.category?.id != categoryId) {
        return false;
      }

      if (woodOnly != null && article.isWood != woodOnly) {
        return false;
      }

      return true;
    }).toList();

    filteredArticles.assignAll(result);
    visibleCount.value = pageSize;
    status.value = result.isEmpty ? ViewStatus.empty : ViewStatus.success;
  }
}
