import 'package:get/get.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../models/analytics_dto.dart';
import '../models/treasury_dto.dart';
import '../services/analytics_service.dart';
import '../services/treasury_service.dart';

/// GetX Controller managing Home Dashboard state, Treasury caisse cards, and Admin Analytics data loading.
class HomeController extends GetxController {
  final AnalyticsService _analyticsService = AnalyticsService();
  final TreasuryService _treasuryService = TreasuryService();
  final StorageService storage = StorageService.instance;

  // View state status for analytics & treasury
  final status = ViewStatus.initial.obs;
  final errorMessage = RxnString();

  // Admin Analytics metrics & datasets
  final monthlySales = 0.0.obs;
  final monthlyPurchaseTtc = 0.0.obs;
  final supplierChartPoints = <SupplierChartPointDto>[].obs;
  final customerReceivables = <CustomerReceivableDto>[].obs;

  // Admin Treasury & Caisses metrics (Caisse Principale & Caisse par Point de Vente)
  final caissePrincipaleBalance = 0.0.obs;
  final siteCaisseBalances = <SiteCaisseBalanceDto>[].obs;

  // Filters state
  final selectedYear = DateTime.now().year.obs;
  final selectedMonth = DateTime.now().month.obs;
  final receivablesSearchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (storage.isAdmin) {
      loadAdminAnalytics();
    }
  }

  /// Computed total cash balance across all store site caisses.
  double get totalSitesCaisseBalance {
    return siteCaisseBalances.fold(0.0, (sum, site) => sum + site.currentBalance);
  }

  /// Loads admin analytics and treasury caisse balances concurrently from the backend API.
  Future<void> loadAdminAnalytics() async {
    status.value = ViewStatus.loading;
    errorMessage.value = null;

    try {
      final results = await Future.wait([
        _analyticsService.fetchDashboardKpis(
          month: selectedMonth.value,
          year: selectedYear.value,
        ),
        _analyticsService.fetchMonthlyPurchaseTtc(
          year: selectedYear.value,
          month: selectedMonth.value,
        ),
        _analyticsService.fetchSupplierPurchasePaymentChart(
          year: selectedYear.value,
          month: selectedMonth.value,
        ),
        _treasuryService.fetchCaissePrincipaleBalance(),
        _treasuryService.fetchAllCaisseBalances(),
      ]);

      final kpis = results[0] as DashboardKpiDto;
      final purchasesTtc = results[1] as double;
      final chartData = results[2] as List<SupplierChartPointDto>;
      final mainCaisse = results[3] as double;
      final siteCaisses = results[4] as List<SiteCaisseBalanceDto>;

      monthlySales.value = kpis.monthlySales;
      monthlyPurchaseTtc.value = purchasesTtc;
      customerReceivables.assignAll(kpis.customerReceivables);
      supplierChartPoints.assignAll(chartData);
      caissePrincipaleBalance.value = mainCaisse;
      siteCaisseBalances.assignAll(siteCaisses);

      status.value = ViewStatus.success;
    } catch (e) {
      status.value = ViewStatus.error;
      errorMessage.value = 'Impossible de charger les données analytiques et trésorerie';
    }
  }

  /// Computed list of customer receivables filtered by search query.
  List<CustomerReceivableDto> get filteredReceivables {
    final query = receivablesSearchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return customerReceivables;
    return customerReceivables.where((c) => c.name.toLowerCase().contains(query)).toList();
  }
}
