import 'package:get/get.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/view_status.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomersController extends GetxController {
  static const int pageSize = 20;

  final CustomerService _customerService = CustomerService();

  final status = ViewStatus.initial.obs;
  final errorMessage = RxnString();

  final _allCustomers = <Customer>[].obs;
  final filteredCustomers = <Customer>[].obs;
  final visibleCount = pageSize.obs;

  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
    debounce(searchQuery, (_) => _applyFilters(),
        time: const Duration(milliseconds: 300));
  }

  List<Customer> get displayedCustomers =>
      filteredCustomers.take(visibleCount.value).toList();

  bool get hasMore => visibleCount.value < filteredCustomers.length;

  Future<void> fetchCustomers() async {
    status.value = ViewStatus.loading;
    errorMessage.value = null;

    try {
      final customersList = await _customerService.fetchAll();
      _allCustomers.assignAll(customersList);
      _applyFilters();
    } on ApiException catch (e) {
      status.value = ViewStatus.error;
      errorMessage.value = e.message;
    }
  }

  Future<void> refreshCustomers() => fetchCustomers();

  void loadMore() {
    if (!hasMore) return;
    visibleCount.value =
        (visibleCount.value + pageSize).clamp(0, filteredCustomers.length);
  }

  void search(String query) {
    searchQuery.value = query;
  }

  void _applyFilters() {
    final query = searchQuery.value.trim().toLowerCase();

    final result = _allCustomers.where((customer) {
      if (query.isNotEmpty) {
        final matchesName = customer.name?.toLowerCase().contains(query) ?? false;
        final matchesFirstname =
            customer.firstname?.toLowerCase().contains(query) ?? false;
        final matchesLastname =
            customer.lastname?.toLowerCase().contains(query) ?? false;
        final matchesPhone =
            customer.phoneNumberOne?.toLowerCase().contains(query) ?? false;
        final matchesDesc =
            customer.description?.toLowerCase().contains(query) ?? false;

        if (!matchesName &&
            !matchesFirstname &&
            !matchesLastname &&
            !matchesPhone &&
            !matchesDesc) {
          return false;
        }
      }
      return true;
    }).toList();

    filteredCustomers.assignAll(result);
    visibleCount.value = pageSize;
    status.value = result.isEmpty ? ViewStatus.empty : ViewStatus.success;
  }
}
