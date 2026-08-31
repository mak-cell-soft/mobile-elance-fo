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

  // Filters state (matching Next.js elance-app.ui analytics page)
  final selectedYear = DateTime.now().year.obs;
  final selectedMonth = RxnInt(DateTime.now().month); // null = "Tous les mois" (ALL), 1..12
  final receivablesSearchQuery = ''.obs;

  /// Month options mapping matching fo-acya-app/elance-app.ui
  static const Map<int?, String> monthOptions = {
    null: 'Tous les mois',
    1: 'Janvier',
    2: 'Février',
    3: 'Mars',
    4: 'Avril',
    5: 'Mai',
    6: 'Juin',
    7: 'Juillet',
    8: 'Août',
    9: 'Septembre',
    10: 'Octobre',
    11: 'Novembre',
    12: 'Décembre',
  };

  /// Dynamic list of years (Current Year, Current Year - 1, Current Year - 2)
  List<int> get availableYears {
    final currentYear = DateTime.now().year;
    return [currentYear, currentYear - 1, currentYear - 2];
  }

  /// Updates selected year filter and triggers analytics refetch
  void updateYear(int year) {
    if (selectedYear.value != year) {
      selectedYear.value = year;
      loadAdminAnalytics();
    }
  }

  /// Updates selected month filter and triggers analytics refetch
  void updateMonth(int? month) {
    if (selectedMonth.value != month) {
      selectedMonth.value = month;
      loadAdminAnalytics();
    }
  }

  /// Dynamic title for sales KPI card
  String get salesKpiTitle => selectedMonth.value == null ? 'CA Année' : 'CA Mois';

  /// Dynamic period badge for sales KPI card
  String get salesPeriodLabel {
    if (selectedMonth.value == null) {
      return 'Année ${selectedYear.value}';
    }
    final isCurrentMonth = selectedMonth.value == DateTime.now().month && selectedYear.value == DateTime.now().year;
    return isCurrentMonth ? 'Ce mois' : monthOptions[selectedMonth.value] ?? 'Ce mois';
  }

  /// Dynamic title for purchases KPI card
  String get purchasesKpiTitle => selectedMonth.value == null ? 'CA Année Achat' : 'CA Mois Achat';

  /// Dynamic period badge for purchases KPI card
  String get purchasesPeriodLabel {
    if (selectedMonth.value == null) {
      return 'Achats (Année)';
    }
    return 'Achats (TTC)';
  }

  // Separate Treasury view status for independent error/loading handling
  final treasuryStatus = ViewStatus.initial.obs;
  final treasuryErrorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    // Load treasury caisse data and executive analytics data on initialization
    loadTreasuryData();
    loadAdminAnalytics();
  }

  /// Unified refresh handler for pull-to-refresh action in HomeView
  Future<void> loadData() async {
    await Future.wait([
      loadTreasuryData(),
      loadAdminAnalytics(),
    ]);
  }

  /// Computed total cash balance across all store site caisses.
  double get totalSitesCaisseBalance {
    return siteCaisseBalances.fold(0.0, (sum, site) => sum + site.currentBalance);
  }

  /// Loads Caisse Principale & Caisse par Point de Vente balances independently from the backend API.
  /// Decoupled from analytics so network or permission failures in analytics never suppress treasury cards.
  Future<void> loadTreasuryData() async {
    treasuryStatus.value = ViewStatus.loading;
    treasuryErrorMessage.value = null;

    try {
      // Fetch central vault balance and site caisse balances concurrently
      final results = await Future.wait([
        _treasuryService.fetchCaissePrincipaleBalance(),
        _treasuryService.fetchAllCaisseBalances(),
      ]);

      caissePrincipaleBalance.value = results[0] as double;
      siteCaisseBalances.assignAll(results[1] as List<SiteCaisseBalanceDto>);
      treasuryStatus.value = ViewStatus.success;
    } catch (e) {
      // NOTE: Fallback gracefully to zero balance on error so app stays responsive
      treasuryStatus.value = ViewStatus.error;
      treasuryErrorMessage.value = 'Impossible de charger la trésorerie caisses';
    }
  }

  /// Loads admin analytics KPI metrics & charts concurrently from the backend API.
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
      ]);

      final kpis = results[0] as DashboardKpiDto;
      final purchasesTtc = results[1] as double;
      final chartData = results[2] as List<SupplierChartPointDto>;

      monthlySales.value = kpis.monthlySales;
      monthlyPurchaseTtc.value = purchasesTtc;
      customerReceivables.assignAll(kpis.customerReceivables);
      supplierChartPoints.assignAll(chartData);

      status.value = ViewStatus.success;
    } catch (e) {
      status.value = ViewStatus.error;
      errorMessage.value = 'Impossible de charger les données analytiques (Admin)';
    }
  }

  /// Computed list of customer receivables filtered by search query.
  List<CustomerReceivableDto> get filteredReceivables {
    final query = receivablesSearchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return customerReceivables;
    return customerReceivables.where((c) => c.name.toLowerCase().contains(query)).toList();
  }
}
