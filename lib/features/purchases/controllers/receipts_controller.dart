import 'package:get/get.dart';
import '../../../core/utils/view_status.dart';
import '../models/receipt_document.dart';
import '../models/supplier.dart';
import '../services/receipt_service.dart';

/// NOTE: GetX Controller managing the Bons de Réception (BR) list,
/// period navigation (month/year/day), client-side search, supplier filtering,
/// live KPI aggregations, and detail modal states.
class ReceiptsController extends GetxController {
  final ReceiptService _service;

  ReceiptsController({ReceiptService? service})
      : _service = service ?? ReceiptService();

  // --- STATE VARIABLES ---
  final status = ViewStatus.initial.obs;
  final errorMessage = RxnString();

  /// Raw document collection fetched from API for the selected accounting period
  final rawDocuments = <ReceiptDocument>[].obs;

  /// Supplier catalogue list for dropdown filter
  final suppliers = <SupplierItem>[].obs;

  /// Current active accounting period
  /// Default initialized to current date (current month and year)
  final currentDate = DateTime.now().obs;

  /// Selected day filter: 0 = "TOUT LE MOIS", 1..31 = specific day
  final selectedDay = 0.obs;

  /// Search keyword
  final searchTerm = ''.obs;

  /// Selected supplier ID filter (null = "Tous les Fournisseurs")
  final selectedSupplierId = RxnInt();

  /// Document currently opened for detailed inspection
  final selectedDocument = Rxn<ReceiptDocument>();

  // --- GETTERS & PERIOD RESOLUTION ---

  int get selectedMonth => currentDate.value.month; // 1-12
  int get selectedYear => currentDate.value.year;

  /// Total days count in the currently selected month
  int get daysInCurrentMonth =>
      DateTime(selectedYear, selectedMonth + 1, 0).day;

  /// French month names list matching elance-app.ui
  static const List<String> monthNames = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  static const List<String> shortMonthNames = [
    'Jan',
    'Fév',
    'Mar',
    'Avr',
    'Mai',
    'Juin',
    'Juil',
    'Aoû',
    'Sep',
    'Oct',
    'Nov',
    'Déc',
  ];

  String get currentMonthName => monthNames[selectedMonth - 1];

  @override
  void onInit() {
    super.onInit();
    loadSuppliers();
    loadReceipts();
  }

  // --- DATA FETCHING ---

  /// Loads suppliers list once for the filter dropdown
  Future<void> loadSuppliers() async {
    try {
      final list = await _service.fetchSuppliers();
      suppliers.assignAll(list);
    } catch (_) {
      // Non-critical: filtering will still function for "Tous" if suppliers fail to load
    }
  }

  /// Fetches receipts for the active period from the backend
  Future<void> loadReceipts() async {
    status.value = ViewStatus.loading;
    errorMessage.value = null;

    try {
      final docs = await _service.fetchReceiptsFiltered(
        month: selectedMonth,
        year: selectedYear,
        day: selectedDay.value,
      );

      rawDocuments.assignAll(docs);
      status.value = docs.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } catch (e) {
      errorMessage.value = e.toString();
      status.value = ViewStatus.error;
    }
  }

  /// Refreshes current period data (for pull-to-refresh)
  Future<void> refreshReceipts() async {
    await loadReceipts();
  }

  // --- PERIOD NAVIGATION ---

  /// Moves to the previous month and reloads data
  void prevMonth() {
    final cur = currentDate.value;
    final newDate = DateTime(cur.year, cur.month - 1, 1);
    currentDate.value = newDate;

    // Reset day if it exceeds max days in new month
    if (selectedDay.value > daysInCurrentMonth) {
      selectedDay.value = 0;
    }

    loadReceipts();
  }

  /// Moves to the next month and reloads data
  void nextMonth() {
    final cur = currentDate.value;
    final newDate = DateTime(cur.year, cur.month + 1, 1);
    currentDate.value = newDate;

    if (selectedDay.value > daysInCurrentMonth) {
      selectedDay.value = 0;
    }

    loadReceipts();
  }

  /// Selects a specific month index (1..12) within the current year
  void selectMonth(int month) {
    if (month == selectedMonth) return;
    currentDate.value = DateTime(selectedYear, month, 1);

    if (selectedDay.value > daysInCurrentMonth) {
      selectedDay.value = 0;
    }

    loadReceipts();
  }

  /// Selects day filter (0 = all month, 1..31 = specific day)
  void setDay(int day) {
    if (selectedDay.value == day) return;
    selectedDay.value = day;
    loadReceipts();
  }

  // --- SEARCH & FILTERING ---

  void setSearchTerm(String term) {
    searchTerm.value = term;
  }

  void setSupplierFilter(int? supplierId) {
    selectedSupplierId.value = supplierId;
  }

  void clearFilters() {
    searchTerm.value = '';
    selectedSupplierId.value = null;
    selectedDay.value = 0;
    loadReceipts();
  }

  /// Live filtered documents computed from raw collection, search query, and supplier filter
  List<ReceiptDocument> get filteredDocuments {
    final term = searchTerm.value.trim().toLowerCase();
    final supId = selectedSupplierId.value;

    return rawDocuments.where((doc) {
      // 1. Supplier filter
      if (supId != null && supId > 0 && doc.counterpart?.id != supId) {
        return false;
      }

      // 2. Search keyword filter
      if (term.isNotEmpty) {
        final docNum = doc.docnumber.toLowerCase();
        final supplierRef = (doc.supplierReference ?? '').toLowerCase();
        final supplierName = (doc.counterpart?.displayName ?? '').toLowerCase();
        final desc = (doc.description ?? '').toLowerCase();

        final matches = docNum.contains(term) ||
            supplierRef.contains(term) ||
            supplierName.contains(term) ||
            desc.contains(term);

        if (!matches) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => (b.docnumber).compareTo(a.docnumber));
  }

  // --- KPI TOTALS (Matching elance-app.ui) ---

  /// Sum of Volume HT Net for the filtered dataset
  double get totalHtNet {
    return filteredDocuments.fold<double>(
      0.0,
      (acc, doc) => acc + doc.totalHtNetDoc,
    );
  }

  /// Sum of Total TTC for the filtered dataset
  double get totalTtcCumule {
    return filteredDocuments.fold<double>(
      0.0,
      (acc, doc) => acc + (doc.totalNetPayable ?? doc.totalNetTtc),
    );
  }

  /// Count of matching documents
  int get filteredCount => filteredDocuments.length;

  // --- DETAIL MODAL ---

  void selectDocumentForDetail(ReceiptDocument doc) {
    selectedDocument.value = doc;
  }

  void closeDetail() {
    selectedDocument.value = null;
  }
}
