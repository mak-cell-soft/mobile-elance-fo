import 'dart:async';
import 'package:get/get.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../models/production_order.dart';
import '../services/production_service.dart';

/// GetX Controller managing Production Dashboard and Order Details state.
/// Exclusively handles read-only workflows: KPI aggregation, status filtering, debounced search, and order details.
class ProductionController extends GetxController {
  final ProductionService _service;
  final bool _autoFetch;

  ProductionController({ProductionService? service, bool autoFetch = true})
    : _service = service ?? ProductionService(),
      _autoFetch = autoFetch;

  final StorageService storage = StorageService.instance;

  // View state status for production orders list
  final status = ViewStatus.initial.obs;
  final errorMessage = RxnString();
  final isModuleDisabledForTenant = false.obs;

  // Master collection of production orders loaded from backend
  final orders = <ProductionOrder>[].obs;

  // Status filtering state (null = 'Tous')
  final selectedFilter = Rxn<ProductionStatus>();

  // Search state and debouncing timer
  final searchQuery = ''.obs;
  Timer? _searchDebounceTimer;

  // Concurrency guard to prevent overlapping refresh requests
  bool _isFetching = false;

  // Order Details state
  final selectedOrder = Rxn<ProductionOrder>();
  final detailStatus = ViewStatus.initial.obs;
  final detailErrorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    if (_autoFetch) {
      fetchOrders();
    }
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    super.onClose();
  }

  // ── Summary Indicators (Computed from actual collection) ────────────────────

  /// Total count of all production orders in the collection.
  int get totalCount => orders.length;

  /// Active orders currently in progress.
  int get inProgressCount =>
      orders.where((o) => o.status == ProductionStatus.inProgress).length;

  /// Orders scheduled for future manufacturing.
  int get plannedCount =>
      orders.where((o) => o.status == ProductionStatus.planned).length;

  /// Orders that are finished (Completed) or validated into inventory (Validated).
  int get completedOrValidatedCount => orders
      .where(
        (o) =>
            o.status == ProductionStatus.completed ||
            o.status == ProductionStatus.validated,
      )
      .length;

  /// Orders that were cancelled (kept distinct from active orders).
  int get cancelledCount =>
      orders.where((o) => o.status == ProductionStatus.cancelled).length;

  // ── Filtered Collection ─────────────────────────────────────────────────────

  /// Computed list of production orders matching the active status filter and search query.
  List<ProductionOrder> get filteredOrders {
    final query = searchQuery.value.trim().toLowerCase();
    final filter = selectedFilter.value;

    return orders.where((order) {
      // 1. Status Filter Check
      if (filter != null && order.status != filter) {
        return false;
      }

      // 2. Search Query Check (Reference or Description)
      if (query.isNotEmpty) {
        final matchesRef = order.reference.toLowerCase().contains(query);
        final matchesDesc =
            order.description?.toLowerCase().contains(query) ?? false;
        final matchesSite =
            order.salesSiteName?.toLowerCase().contains(query) ?? false;
        if (!matchesRef && !matchesDesc && !matchesSite) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ── Actions & Data Loading ──────────────────────────────────────────────────

  /// Sets or clears the active status filter.
  void setFilter(ProductionStatus? filter) {
    if (selectedFilter.value != filter) {
      selectedFilter.value = filter;
    }
  }

  /// Debounced search input handler (300ms delay to avoid stuttering on keystroke).
  void onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      searchQuery.value = query;
    });
  }

  /// Clears the search input and resets search state.
  void clearSearch() {
    _searchDebounceTimer?.cancel();
    searchQuery.value = '';
  }

  /// Fetches production orders from the backend API.
  Future<void> fetchOrders() async {
    if (_isFetching) return;
    _isFetching = true;

    status.value = ViewStatus.loading;
    errorMessage.value = null;
    isModuleDisabledForTenant.value = false;

    try {
      final results = await _service.fetchAll();
      orders.assignAll(results);
      status.value = ViewStatus.success;
    } on ApiException catch (e) {
      status.value = ViewStatus.error;
      if (e.statusCode == 403) {
        isModuleDisabledForTenant.value = true;
        errorMessage.value =
            'Le module Production n\'est pas activé pour cette entreprise.';
      } else {
        errorMessage.value = e.message.isNotEmpty
            ? e.message
            : 'Impossible de charger les ordres de fabrication';
      }
    } catch (_) {
      status.value = ViewStatus.error;
      errorMessage.value = 'Erreur inattendue lors du chargement des ordres';
    } finally {
      _isFetching = false;
    }
  }

  /// Pull-to-refresh handler.
  Future<void> refreshOrders() async {
    await fetchOrders();
  }

  /// Fetches fresh order details for the given order ID.
  Future<void> loadOrderDetail(int id) async {
    detailStatus.value = ViewStatus.loading;
    detailErrorMessage.value = null;

    try {
      final order = await _service.fetchById(id);
      selectedOrder.value = order;
      detailStatus.value = ViewStatus.success;
    } on ApiException catch (e) {
      detailStatus.value = ViewStatus.error;
      detailErrorMessage.value = e.message.isNotEmpty
          ? e.message
          : 'Impossible de charger les détails de l\'ordre #$id';
    } catch (_) {
      detailStatus.value = ViewStatus.error;
      detailErrorMessage.value =
          'Erreur inattendue lors de la récupération de l\'ordre';
    }
  }
}
