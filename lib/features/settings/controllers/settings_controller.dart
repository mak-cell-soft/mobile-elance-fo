import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/view_status.dart';
import '../models/app_variable.dart';
import '../services/settings_service.dart';

class SettingsController extends GetxController {
  final SettingsService _service = SettingsService();

  final ceilingStatus = ViewStatus.initial.obs;
  final workflowStatus = ViewStatus.initial.obs;

  final errorMessage = RxnString();
  final isSavingCeiling = false.obs;
  final isTogglingWorkflow = false.obs;

  final dailyCeilings = <AppVariable>[].obs;
  final workflows = <AppVariable>[].obs;

  // Form controllers for Daily Ceiling
  final amountController = TextEditingController();
  final selectedDate = Rx<DateTime>(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }

  Future<void> loadAll() async {
    await Future.wait([
      fetchDailyCeilings(),
      fetchWorkflows(),
    ]);
  }

  // --- TAB 1: PLAFOND JOURNALIER ---

  Future<void> fetchDailyCeilings() async {
    ceilingStatus.value = ViewStatus.loading;
    try {
      final list = await _service.fetchVariables('DailyInvoiceCeiling');
      // Sort by date name descending
      list.sort((a, b) => (b.name ?? '').compareTo(a.name ?? ''));
      dailyCeilings.assignAll(list);
      ceilingStatus.value = list.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } on ApiException catch (e) {
      ceilingStatus.value = ViewStatus.error;
      errorMessage.value = e.message;
    }
  }

  /// Finds today's ceiling variable if configured & active
  AppVariable? get todayCeiling {
    final todayStr = _formatDateKey(DateTime.now());
    return dailyCeilings.firstWhereOrNull(
      (c) => c.name == todayStr && c.active && !(c.isDeleted ?? false),
    );
  }

  Future<bool> saveDailyCeiling() async {
    final amountText = amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      errorMessage.value = 'Veuillez saisir un montant valide supérieur à 0.';
      return false;
    }

    isSavingCeiling.value = true;
    errorMessage.value = null;

    final dateStr = _formatDateKey(selectedDate.value);

    try {
      await _service.upsertDailyCeiling(dateStr, amountText);
      amountController.clear();
      await fetchDailyCeilings();
      isSavingCeiling.value = false;
      return true;
    } on ApiException catch (e) {
      isSavingCeiling.value = false;
      errorMessage.value = e.message;
      return false;
    }
  }

  Future<void> toggleCeilingActive(AppVariable item, bool active) async {
    if (item.id == null) return;
    try {
      final model = item.toJson();
      model['isactive'] = active;
      await _service.updateVariable(item.id!, model);
      await fetchDailyCeilings();
    } on ApiException catch (e) {
      Get.snackbar('Erreur', e.message, backgroundColor: Colors.red.shade100);
    }
  }

  Future<void> deleteCeiling(int id) async {
    try {
      await _service.deleteVariable(id);
      await fetchDailyCeilings();
    } on ApiException catch (e) {
      Get.snackbar('Erreur', e.message, backgroundColor: Colors.red.shade100);
    }
  }

  // --- TAB 2: FLUX & AUTOMATIONS (WORKFLOW) ---

  Future<void> fetchWorkflows() async {
    workflowStatus.value = ViewStatus.loading;
    try {
      final list = await _service.fetchVariables('Workflow');
      workflows.assignAll(list);
      workflowStatus.value = list.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } on ApiException catch (e) {
      workflowStatus.value = ViewStatus.error;
      errorMessage.value = e.message;
    }
  }

  AppVariable? get autoPaymentVar =>
      workflows.firstWhereOrNull((w) => w.name == 'AutoPaymentOnInvoice');

  bool get autoPaymentActive => autoPaymentVar?.active ?? false;

  Future<void> toggleAutoPayment(bool active) async {
    isTogglingWorkflow.value = true;
    try {
      final existing = autoPaymentVar;
      if (existing != null && existing.id != null) {
        final model = existing.toJson();
        model['isactive'] = active;
        await _service.updateVariable(existing.id!, model);
      } else {
        await _service.addVariable({
          'nature': 'Workflow',
          'name': 'AutoPaymentOnInvoice',
          'value': '1',
          'isactive': active,
          'isdefault': false,
          'iseditable': true,
          'isdeleted': false,
        });
      }
      await fetchWorkflows();
    } on ApiException catch (e) {
      Get.snackbar('Erreur', e.message, backgroundColor: Colors.red.shade100);
    } finally {
      isTogglingWorkflow.value = false;
    }
  }

  AppVariable? get rsBlockingVar =>
      workflows.firstWhereOrNull((w) => w.name == 'InvoiceWithoutRSBlocking');

  bool get rsBlockingActive => rsBlockingVar?.active ?? false;

  Future<void> toggleRSBlocking(bool active) async {
    isTogglingWorkflow.value = true;
    try {
      final existing = rsBlockingVar;
      if (existing != null && existing.id != null) {
        final model = existing.toJson();
        model['isactive'] = active;
        await _service.updateVariable(existing.id!, model);
      } else {
        await _service.addVariable({
          'nature': 'Workflow',
          'name': 'InvoiceWithoutRSBlocking',
          'value': '1',
          'isactive': active,
          'isdefault': false,
          'iseditable': true,
          'isdeleted': false,
        });
      }
      await fetchWorkflows();
    } on ApiException catch (e) {
      Get.snackbar('Erreur', e.message, backgroundColor: Colors.red.shade100);
    } finally {
      isTogglingWorkflow.value = false;
    }
  }

  String _formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
