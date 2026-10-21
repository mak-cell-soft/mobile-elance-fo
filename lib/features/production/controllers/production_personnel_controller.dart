import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../models/production_personnel_models.dart';
import '../services/production_service.dart';

/// Active sub-tab under Production Personnel & Prestations.
enum PersonnelSubView {
  /// Monthly calculated summary and employee-by-employee remuneration breakdown.
  monthly,

  /// Standalone other work prestations outside fabrication orders.
  otherWork,
}

/// GetX controller managing state, data loading, period filtering,
/// and authorization guards for Production Personnel & Prestations.
/// Reuses existing C# REST backend endpoints:
/// - GET /api/production/payables/monthly
/// - GET /api/production/other-work
class ProductionPersonnelController extends GetxController {
  final ProductionService _service;
  final bool _autoFetch;

  ProductionPersonnelController({
    ProductionService? service,
    bool autoFetch = true,
  })  : _service = service ?? ProductionService(),
        _autoFetch = autoFetch;

  final StorageService storage = StorageService.instance;

  // Active view switcher (Monthly calculated summary vs Prestations hors ordres)
  final activeSubView = PersonnelSubView.monthly.obs;

  // Date selection state for monthly calculations (default to current month/year)
  final selectedYear = DateTime.now().year.obs;
  final selectedMonth = DateTime.now().month.obs;

  // Monthly summary state
  final summary = Rxn<MonthlyEmployeePayableSummary>();
  final monthlyStatus = ViewStatus.initial.obs;
  final monthlyErrorMessage = RxnString();

  // Standalone other work list state
  final otherWorkList = <ProductionOtherWorkEntry>[].obs;
  final otherWorkStatus = ViewStatus.initial.obs;
  final otherWorkErrorMessage = RxnString();

  // Filters for standalone other work
  final filterStartDate = Rxn<DateTime>();
  final filterEndDate = Rxn<DateTime>();
  final filterPersonId = RxnInt();

  // Expandable cards tracking per employee
  final expandedEmployeeIds = <int>{}.obs;

  // Concurrency guards
  bool _isFetchingMonthly = false;
  bool _isFetchingOtherWork = false;

  /// Checks whether the user is authorized to view production employee payment data.
  /// Matches web permission guard: requires Admin/SuperAdmin or 'production' read permission.
  bool get canAccess =>
      storage.isAdmin || storage.hasPermission('production', action: 'canRead');

  @override
  void onInit() {
    super.onInit();
    if (_autoFetch) {
      if (canAccess) {
        fetchMonthlySummary();
        fetchOtherWork();
      } else {
        monthlyStatus.value = ViewStatus.error;
        monthlyErrorMessage.value =
            'Accès non autorisé aux rémunérations du personnel de production.';
      }
    }
  }

  /// Changes the selected month by [delta] (-1 or +1), handling year wrapping.
  Future<void> changeMonth(int delta) async {
    int newMonth = selectedMonth.value + delta;
    int newYear = selectedYear.value;

    if (newMonth < 1) {
      newMonth = 12;
      newYear -= 1;
    } else if (newMonth > 12) {
      newMonth = 1;
      newYear += 1;
    }

    selectedMonth.value = newMonth;
    selectedYear.value = newYear;
    await fetchMonthlySummary();
  }

  /// Explicitly sets the month and triggers fresh calculation.
  Future<void> setMonth(int month) async {
    if (month >= 1 && month <= 12 && month != selectedMonth.value) {
      selectedMonth.value = month;
      await fetchMonthlySummary();
    }
  }

  /// Explicitly sets the year and triggers fresh calculation.
  Future<void> setYear(int year) async {
    if (year != selectedYear.value) {
      selectedYear.value = year;
      await fetchMonthlySummary();
    }
  }

  /// Switches active sub-view between monthly calculated summary and outside-order prestations.
  void setSubView(PersonnelSubView subView) {
    if (activeSubView.value != subView) {
      activeSubView.value = subView;
      if (subView == PersonnelSubView.otherWork && otherWorkStatus.value == ViewStatus.initial) {
        fetchOtherWork();
      }
    }
  }

  /// Toggles accordion expansion for an individual employee's breakdown card.
  void toggleEmployeeExpanded(int personId) {
    if (expandedEmployeeIds.contains(personId)) {
      expandedEmployeeIds.remove(personId);
    } else {
      expandedEmployeeIds.add(personId);
    }
  }

  /// Fetches monthly calculated employee payable summary from GET /api/production/payables/monthly.
  Future<void> fetchMonthlySummary() async {
    if (!canAccess) {
      monthlyStatus.value = ViewStatus.error;
      monthlyErrorMessage.value =
          'Accès non autorisé aux rémunérations du personnel de production.';
      return;
    }

    if (_isFetchingMonthly) return;
    _isFetchingMonthly = true;

    monthlyStatus.value = ViewStatus.loading;
    monthlyErrorMessage.value = null;

    try {
      final res = await _service.fetchMonthlyPayableSummary(
        year: selectedYear.value,
        month: selectedMonth.value,
      );
      summary.value = res;
      monthlyStatus.value = ViewStatus.success;
    } on ApiException catch (e) {
      monthlyStatus.value = ViewStatus.error;
      monthlyErrorMessage.value = e.message.isNotEmpty
          ? e.message
          : 'Impossible de récupérer le récapitulatif mensuel.';
      debugPrint('[ProductionPersonnelController] API Error: ${e.message}');
    } catch (e) {
      monthlyStatus.value = ViewStatus.error;
      monthlyErrorMessage.value =
          'Erreur inattendue lors du calcul des rémunérations mensuelles.';
      debugPrint('[ProductionPersonnelController] Unexpected Error: $e');
    } finally {
      _isFetchingMonthly = false;
    }
  }

  /// Fetches standalone prestations outside orders from GET /api/production/other-work.
  Future<void> fetchOtherWork() async {
    if (!canAccess) {
      otherWorkStatus.value = ViewStatus.error;
      otherWorkErrorMessage.value =
          'Accès non autorisé aux prestations de travail.';
      return;
    }

    if (_isFetchingOtherWork) return;
    _isFetchingOtherWork = true;

    otherWorkStatus.value = ViewStatus.loading;
    otherWorkErrorMessage.value = null;

    try {
      final res = await _service.fetchOtherWorkEntries(
        startDate: filterStartDate.value,
        endDate: filterEndDate.value,
        personId: filterPersonId.value,
      );
      otherWorkList.assignAll(res);
      otherWorkStatus.value = ViewStatus.success;
    } on ApiException catch (e) {
      otherWorkStatus.value = ViewStatus.error;
      otherWorkErrorMessage.value = e.message.isNotEmpty
          ? e.message
          : 'Impossible de récupérer les prestations hors ordres.';
      debugPrint('[ProductionPersonnelController] OtherWork API Error: ${e.message}');
    } catch (e) {
      otherWorkStatus.value = ViewStatus.error;
      otherWorkErrorMessage.value =
          'Erreur inattendue lors de la récupération des prestations.';
      debugPrint('[ProductionPersonnelController] OtherWork Unexpected Error: $e');
    } finally {
      _isFetchingOtherWork = false;
    }
  }

  /// Pull-to-refresh handler refreshing the currently visible tab.
  Future<void> refreshActiveView() async {
    if (activeSubView.value == PersonnelSubView.monthly) {
      await fetchMonthlySummary();
    } else {
      await fetchOtherWork();
    }
  }

  /// Refreshes all data in the controller.
  Future<void> refreshAll() async {
    await Future.wait([
      fetchMonthlySummary(),
      fetchOtherWork(),
    ]);
  }
}
