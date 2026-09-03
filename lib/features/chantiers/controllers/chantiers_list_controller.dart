import 'package:get/get.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/view_status.dart';
import '../models/chantier_list_item.dart';
import '../services/chantier_service.dart';

/// GetX controller managing the list of chantiers, real-time search,
/// and status filtering (All, InProgress, Planned, Completed).
class ChantiersListController extends GetxController {
  final ChantierService _service = ChantierService();

  final status = ViewStatus.initial.obs;
  final errorMessage = RxnString();

  final _allChantiers = <ChantierListItem>[].obs;
  final filteredChantiers = <ChantierListItem>[].obs;

  final searchQuery = ''.obs;
  final selectedFilter = 'all'.obs; // 'all', 'inProgress', 'completed', 'alert'

  @override
  void onInit() {
    super.onInit();
    fetchChantiers();
    // Debounce search query changes by 250ms
    debounce(searchQuery, (_) => _applyFilters(),
        time: const Duration(milliseconds: 250));
  }

  Future<void> fetchChantiers() async {
    status.value = ViewStatus.loading;
    errorMessage.value = null;

    try {
      final list = await _service.getAll();
      _allChantiers.assignAll(list);
      _applyFilters();
      status.value = ViewStatus.success;
    } on ApiException catch (e) {
      status.value = ViewStatus.error;
      errorMessage.value = e.message;
    } catch (e) {
      status.value = ViewStatus.error;
      errorMessage.value = 'Impossible de charger la liste des chantiers.';
    }
  }

  Future<void> refreshChantiers() => fetchChantiers();

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void setFilter(String filter) {
    if (selectedFilter.value != filter) {
      selectedFilter.value = filter;
      _applyFilters();
    }
  }

  void _applyFilters() {
    final query = searchQuery.value.trim().toLowerCase();
    final filter = selectedFilter.value;

    final results = _allChantiers.where((chantier) {
      // Status filter
      if (filter == 'inProgress' &&
          chantier.status.toLowerCase() != 'inprogress') {
        return false;
      }
      if (filter == 'completed' &&
          chantier.status.toLowerCase() != 'completed') {
        return false;
      }
      if (filter == 'alert' &&
          chantier.healthFlag.toLowerCase() != 'red' &&
          chantier.healthFlag.toLowerCase() != 'orange') {
        return false;
      }

      // Search query filter
      if (query.isNotEmpty) {
        final matchesName = chantier.name.toLowerCase().contains(query);
        final matchesRef =
            chantier.reference?.toLowerCase().contains(query) ?? false;
        final matchesLoc =
            chantier.location?.toLowerCase().contains(query) ?? false;
        final matchesArch =
            chantier.architectName?.toLowerCase().contains(query) ?? false;
        return matchesName || matchesRef || matchesLoc || matchesArch;
      }

      return true;
    }).toList();

    filteredChantiers.assignAll(results);
  }

  int get totalCount => _allChantiers.length;
  int get inProgressCount =>
      _allChantiers.where((c) => c.status.toLowerCase() == 'inprogress').length;
  int get alertCount => _allChantiers
      .where((c) =>
          c.healthFlag.toLowerCase() == 'red' ||
          c.healthFlag.toLowerCase() == 'orange')
      .length;
}
