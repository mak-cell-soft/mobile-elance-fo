import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../models/chantier_caisse_summary.dart';
import '../models/chantier_caisse_transaction.dart';
import '../models/chantier_detail.dart';
import '../services/chantier_service.dart';

/// Controller for Chantier detail view, handling Général, Suivi, and Caisse tabs.
/// Includes full cash request creation, admin cash funding, and admin approval flow.
class ChantierDetailController extends GetxController {
  final ChantierService _service = ChantierService();
  final StorageService storage = StorageService.instance;

  late final int chantierId;

  // Tab State: 0 = Général, 1 = Suivi, 2 = Caisse
  final activeTab = 0.obs;

  // Detail & Overview State
  final detailStatus = ViewStatus.initial.obs;
  final detailErrorMessage = RxnString();
  final detail = Rxn<ChantierDetail>();

  // Caisse State
  final caisseStatus = ViewStatus.initial.obs;
  final caisseErrorMessage = RxnString();
  final caisseSummary = Rxn<ChantierCaisseSummary>();
  final transactions = <ChantierCaisseTransaction>[].obs;
  final caisseFilter = 'all'.obs; // 'all', 'entree', 'sortie', 'pending'

  // Suivi State
  final progressEntries = <ChantierProgressEntry>[].obs;
  final alerts = <ChantierAlert>[].obs;

  // Action Loading Indicators
  final isSubmitting = false.obs;
  final validatingTxId = RxnInt();

  bool get isAdmin => storage.isAdmin;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is int) {
      chantierId = args;
    } else if (args is Map && args['id'] != null) {
      chantierId = int.tryParse(args['id'].toString()) ?? 0;
      if (args['tab'] != null) {
        final tabIndex = int.tryParse(args['tab'].toString()) ?? 0;
        activeTab.value = tabIndex;
      }
    } else {
      chantierId = int.tryParse(Get.parameters['id'] ?? '') ?? 0;
    }

    loadAllData();
  }

  /// Loads detail, caisse metrics, and progress logs concurrently
  Future<void> loadAllData() async {
    await Future.wait([
      fetchDetail(),
      fetchCaisseData(),
      fetchSuiviData(),
    ]);
  }

  /// Fetches core Chantier metadata
  Future<void> fetchDetail() async {
    detailStatus.value = ViewStatus.loading;
    detailErrorMessage.value = null;

    try {
      final res = await _service.getById(chantierId);
      detail.value = res;
      detailStatus.value = ViewStatus.success;
    } on ApiException catch (e) {
      detailStatus.value = ViewStatus.error;
      detailErrorMessage.value = e.message;
    } catch (_) {
      detailStatus.value = ViewStatus.error;
      detailErrorMessage.value = 'Impossible de charger les détails du chantier.';
    }
  }

  /// Fetches Caisse balance summary and transactions ledger
  Future<void> fetchCaisseData() async {
    caisseStatus.value = ViewStatus.loading;
    caisseErrorMessage.value = null;

    try {
      final results = await Future.wait([
        _service.getCaisseSummary(chantierId),
        _service.getCaisseTransactions(chantierId),
      ]);

      caisseSummary.value = results[0] as ChantierCaisseSummary;
      transactions.assignAll(results[1] as List<ChantierCaisseTransaction>);
      caisseStatus.value = ViewStatus.success;
    } on ApiException catch (e) {
      caisseStatus.value = ViewStatus.error;
      caisseErrorMessage.value = e.message;
    } catch (_) {
      caisseStatus.value = ViewStatus.error;
      caisseErrorMessage.value = 'Impossible de charger la caisse du chantier.';
    }
  }

  /// Fetches Suivi progress entries & alerts
  Future<void> fetchSuiviData() async {
    try {
      final results = await Future.wait([
        _service.getProgressEntries(chantierId),
        _service.getAlerts(chantierId),
      ]);

      progressEntries.assignAll(results[0] as List<ChantierProgressEntry>);
      alerts.assignAll(results[1] as List<ChantierAlert>);
    } catch (_) {
      // Non-blocking fallback if auxiliary endpoints fail
    }
  }

  // --- Caisse Filter & Computed Collections ---

  void setCaisseFilter(String filter) {
    caisseFilter.value = filter;
  }

  List<ChantierCaisseTransaction> get filteredTransactions {
    final f = caisseFilter.value;
    if (f == 'entree') return transactions.where((t) => t.isEntree).toList();
    if (f == 'sortie') return transactions.where((t) => t.isSortie && t.isCompleted).toList();
    if (f == 'pending') return transactions.where((t) => t.isPending).toList();
    return transactions;
  }

  List<ChantierCaisseTransaction> get pendingRequests {
    return transactions.where((t) => t.isPending).toList();
  }

  int get pendingCount => pendingRequests.length;

  // --- Actions ---

  /// User Action: Submit cash request (Demande d'argent)
  /// Sends `isMobileRequest = true` so it enters pending state for admin review.
  Future<bool> submitCashRequest({
    required double amount,
    required String reason,
    String? notes,
  }) async {
    if (amount <= 0) return false;

    isSubmitting.value = true;
    try {
      await _service.addCaisseSortie(
        chantierId,
        amount: amount,
        reason: reason,
        notes: notes,
        isMobileRequest: true,
      );

      // Refresh caisse ledger immediately so pending request shows up
      await fetchCaisseData();
      isSubmitting.value = false;

      Get.snackbar(
        'Demande envoyée',
        'Votre demande de ${amount.toStringAsFixed(3)} TND a été soumise pour validation.',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return true;
    } on ApiException catch (e) {
      isSubmitting.value = false;
      Get.snackbar(
        'Erreur',
        e.message,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    } catch (_) {
      isSubmitting.value = false;
      Get.snackbar(
        'Erreur',
        'Impossible de soumettre la demande.',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    }
  }

  /// Admin Action: Add funds into chantier cash desk (Alimenter)
  Future<bool> alimenterCaisse({
    required double amount,
    required String reason,
    String? reference,
    String? notes,
    DateTime? transactionDate,
  }) async {
    if (amount <= 0) return false;

    isSubmitting.value = true;
    try {
      await _service.addCaisseAlimentation(
        chantierId,
        amount: amount,
        reason: reason,
        reference: reference,
        notes: notes,
        transactionDate: transactionDate,
      );

      await fetchCaisseData();
      isSubmitting.value = false;

      Get.snackbar(
        'Caisse alimentée',
        'Approvisionnement de ${amount.toStringAsFixed(3)} TND effectué avec succès.',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return true;
    } on ApiException catch (e) {
      isSubmitting.value = false;
      Get.snackbar(
        'Erreur',
        e.message,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    } catch (_) {
      isSubmitting.value = false;
      Get.snackbar(
        'Erreur',
        "Impossible d'alimenter la caisse.",
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    }
  }

  /// Admin Action: Validate or Reject a pending cash request
  Future<void> validatePendingRequest(int txId, bool approve) async {
    validatingTxId.value = txId;

    try {
      await _service.validateCaisseRequest(chantierId, txId, approve: approve);
      await fetchCaisseData();
      validatingTxId.value = null;

      Get.snackbar(
        approve ? 'Demande validée' : 'Demande rejetée',
        approve
            ? 'Le montant a été décaissé de la caisse chantier.'
            : 'La demande a été rejetée.',
        backgroundColor: approve ? const Color(0xFF10B981) : const Color(0xFF6B7280),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } on ApiException catch (e) {
      validatingTxId.value = null;
      Get.snackbar(
        'Erreur',
        e.message,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (_) {
      validatingTxId.value = null;
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour la demande.',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }
}
