import 'package:get/get.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/view_status.dart';
import '../models/article.dart';
import '../models/category.dart';
import '../models/stock.dart';
import '../models/stock_summary.dart';
import '../services/article_service.dart';
import '../services/category_service.dart';
import '../services/stock_service.dart';

/// Handles the full article list, stock aggregation, and category/subcategory filtering flow.
class ArticlesController extends GetxController {
  static const int pageSize = 20;

  final ArticleService _articleService = ArticleService();
  final StockService _stockService = StockService();
  final CategoryService _categoryService = CategoryService();

  final status = ViewStatus.initial.obs;
  final errorMessage = RxnString();

  final _allArticles = <Article>[].obs;
  final filteredArticles = <Article>[].obs;
  final visibleCount = pageSize.obs;

  /// Full list of categories fetched from GET /Category with subcategories.
  final categories = <Category>[].obs;

  /// Holds computed stock total & site breakdown mapped by article ID.
  final stockMap = <int, StockSummary>{}.obs;
  final isStockLoading = false.obs;

  /// Tracks which article card is expanded to reveal site breakdown (Option B).
  final expandedArticleId = RxnInt();

  final searchQuery = ''.obs;
  final selectedCategoryId = RxnInt();
  final selectedSubCategoryId = RxnInt();
  final woodOnlyFilter = RxnBool();

  @override
  void onInit() {
    super.onInit();
    fetchArticles();

    debounce(searchQuery, (_) => _applyFilters(),
        time: const Duration(milliseconds: 300));
    ever(selectedCategoryId, (_) => _applyFilters());
    ever(selectedSubCategoryId, (_) => _applyFilters());
    ever(woodOnlyFilter, (_) => _applyFilters());
  }

  /// List of subcategories for the currently selected category.
  List<SubCategoryRef> get availableSubCategories {
    final categoryId = selectedCategoryId.value;
    if (categoryId == null) return [];
    final category = categories.firstWhereOrNull((c) => c.id == categoryId);
    return category?.firstChildren
            ?.where((sub) => !(sub.isDeleted ?? false))
            .toList() ??
        [];
  }

  /// Returns the number of active filters (excluding search query).
  int get activeFiltersCount {
    int count = 0;
    if (selectedCategoryId.value != null) count++;
    if (selectedSubCategoryId.value != null) count++;
    if (woodOnlyFilter.value != null) count++;
    return count;
  }

  List<Article> get displayedArticles =>
      filteredArticles.take(visibleCount.value).toList();

  bool get hasMore => visibleCount.value < filteredArticles.length;

  Future<void> fetchArticles() async {
    status.value = ViewStatus.loading;
    isStockLoading.value = true;
    errorMessage.value = null;

    try {
      final results = await Future.wait([
        _articleService.fetchAll(),
        _stockService.fetchAll().catchError((_) => <Stock>[]),
        _categoryService.fetchAll().catchError((_) => <Category>[]),
      ]);

      final articlesList = results[0] as List<Article>;
      final stocksList = results[1] as List<Stock>;
      final categoriesList = results[2] as List<Category>;

      _allArticles.assignAll(articlesList);
      categories.assignAll(categoriesList);
      _buildStockMap(stocksList);
      _applyFilters();
    } on ApiException catch (e) {
      status.value = ViewStatus.error;
      errorMessage.value = e.message;
    } finally {
      isStockLoading.value = false;
    }
  }

  /// Map GET /Stock records to StockSummary per article ID matching web app logic.
  void _buildStockMap(List<Stock> stocks) {
    final map = <int, StockSummary>{};
    for (final stock in stocks) {
      final articleId = stock.merchandise?.article?.id;
      if (articleId == null) continue;

      final qty = stock.quantity;
      final siteName = _formatSiteName(stock.site);
      final unit = stock.merchandise?.article?.unit ?? 'PCS';

      final existing = map[articleId] ?? StockSummary(total: 0, breakdown: []);
      final newTotal = existing.total + qty;
      final newBreakdown = List<StockSiteBreakdown>.from(existing.breakdown);

      final existingIndex = newBreakdown.indexWhere((b) => b.siteName == siteName);
      if (existingIndex >= 0) {
        final prev = newBreakdown[existingIndex];
        newBreakdown[existingIndex] = StockSiteBreakdown(
          siteName: siteName,
          quantity: prev.quantity + qty,
          unit: unit,
        );
      } else {
        newBreakdown.add(StockSiteBreakdown(
          siteName: siteName,
          quantity: qty,
          unit: unit,
        ));
      }

      map[articleId] = StockSummary(total: newTotal, breakdown: newBreakdown);
    }
    stockMap.assignAll(map);
  }

  String _formatSiteName(StockSite? site) {
    if (site == null) return 'Dépôt Central';
    final gov = (site.gov ?? '').trim();
    final addr = (site.address ?? '').trim();

    if (gov.isNotEmpty && addr.isNotEmpty) {
      return '$gov - $addr';
    } else if (gov.isNotEmpty) {
      return gov;
    } else if (addr.isNotEmpty) {
      return addr;
    }
    return 'Dépôt Central';
  }

  void toggleExpandArticle(int? articleId) {
    if (articleId == null) return;
    if (expandedArticleId.value == articleId) {
      expandedArticleId.value = null;
    } else {
      expandedArticleId.value = articleId;
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
    // Reset subcategory when category changes matching web behavior
    selectedSubCategoryId.value = null;
  }

  void filterBySubCategory(int? subCategoryId) {
    selectedSubCategoryId.value = subCategoryId;
  }

  void filterByWood(bool? woodOnly) {
    woodOnlyFilter.value = woodOnly;
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedCategoryId.value = null;
    selectedSubCategoryId.value = null;
    woodOnlyFilter.value = null;
  }

  void _applyFilters() {
    final query = searchQuery.value.trim().toLowerCase();
    final categoryId = selectedCategoryId.value;
    final subCategoryId = selectedSubCategoryId.value;
    final woodOnly = woodOnlyFilter.value;

    final result = _allArticles.where((article) {
      if (query.isNotEmpty) {
        final matchesReference =
            article.reference?.toLowerCase().contains(query) ?? false;
        final matchesDescription =
            article.description?.toLowerCase().contains(query) ?? false;
        if (!matchesReference && !matchesDescription) return false;
      }

      if (categoryId != null && article.categoryId != categoryId && article.category?.id != categoryId) {
        return false;
      }

      if (subCategoryId != null && article.subcategoryId != subCategoryId && article.subcategory?.id != subCategoryId) {
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
