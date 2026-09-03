import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/chantier_caisse_summary.dart';
import '../models/chantier_caisse_transaction.dart';
import '../models/chantier_detail.dart';
import '../models/chantier_list_item.dart';

/// Service interfacing with the backend /chantier REST APIs.
/// Reuses existing endpoints from fo-acya-app/elance-app.ui/src/services/chantier/chantier.service.ts.
class ChantierService {
  final Dio _dio = ApiClient.instance.dio;

  /// Fetches all chantiers with optional search query and status filters.
  /// GET /chantier
  Future<List<ChantierListItem>> getAll({
    String? search,
    int? status,
    int? healthFlag,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (status != null) {
        queryParams['status'] = status;
      }
      if (healthFlag != null) {
        queryParams['healthFlag'] = healthFlag;
      }

      final response = await _dio.get('/chantier', queryParameters: queryParams);
      final list = response.data as List<dynamic>;
      return list
          .map((json) => ChantierListItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetches full chantier details by ID.
  /// GET /chantier/{id}
  Future<ChantierDetail> getById(int id) async {
    try {
      final response = await _dio.get('/chantier/$id');
      return ChantierDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetches aggregated caisse financial summary (balance, total in, total out, pending count).
  /// GET /chantier/{id}/caisse
  Future<ChantierCaisseSummary> getCaisseSummary(int id) async {
    try {
      final response = await _dio.get('/chantier/$id/caisse');
      return ChantierCaisseSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetches caisse operations ledger for a chantier.
  /// GET /chantier/{id}/caisse/transactions
  Future<List<ChantierCaisseTransaction>> getCaisseTransactions(
    int id, {
    int? type,
    int? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/chantier/$id/caisse/transactions',
        queryParameters: queryParams,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((json) =>
              ChantierCaisseTransaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Registers cash replenishment (Alimentation) for a chantier's cash desk.
  /// Restricted to Administrator role.
  /// POST /chantier/{id}/caisse/alimentation
  Future<ChantierCaisseTransaction> addCaisseAlimentation(
    int id, {
    required double amount,
    DateTime? transactionDate,
    required String reason,
    String? reference,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'amount': amount,
        if (transactionDate != null)
          'transactionDate': transactionDate.toIso8601String()
        else
          'transactionDate': DateTime.now().toIso8601String(),
        'reason': reason.trim(),
        if (reference != null && reference.isNotEmpty)
          'reference': reference.trim(),
        if (notes != null && notes.isNotEmpty) 'notes': notes.trim(),
      };

      final response = await _dio.post(
        '/chantier/$id/caisse/alimentation',
        data: payload,
      );
      return ChantierCaisseTransaction.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Records a cash disbursement / expense request.
  /// When submitted by a normal field user, [isMobileRequest] is set to true
  /// so that it lands in Pending status awaiting admin approval.
  /// POST /chantier/{id}/caisse/sortie
  Future<ChantierCaisseTransaction> addCaisseSortie(
    int id, {
    required double amount,
    DateTime? transactionDate,
    required String reason,
    int? beneficiaryPersonId,
    String? reference,
    String? notes,
    bool isMobileRequest = true,
  }) async {
    try {
      final payload = <String, dynamic>{
        'amount': amount,
        if (transactionDate != null)
          'transactionDate': transactionDate.toIso8601String()
        else
          'transactionDate': DateTime.now().toIso8601String(),
        'reason': reason.trim(),
        if (beneficiaryPersonId != null)
          'beneficiaryPersonId': beneficiaryPersonId,
        if (reference != null && reference.isNotEmpty)
          'reference': reference.trim(),
        if (notes != null && notes.isNotEmpty) 'notes': notes.trim(),
        'isMobileRequest': isMobileRequest,
      };

      final response = await _dio.post(
        '/chantier/$id/caisse/sortie',
        data: payload,
      );
      return ChantierCaisseTransaction.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Validates or rejects a pending cash disbursement request.
  /// Restricted to Administrator role.
  /// POST /chantier/{id}/caisse/transactions/{txId}/validate
  Future<void> validateCaisseRequest(
    int id,
    int txId, {
    required bool approve,
  }) async {
    try {
      await _dio.post(
        '/chantier/$id/caisse/transactions/$txId/validate',
        data: {'approve': approve},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetches progress history entries for the Suivi timeline.
  /// GET /chantier/{id}/progress-entries
  Future<List<ChantierProgressEntry>> getProgressEntries(int id) async {
    try {
      final response = await _dio.get('/chantier/$id/progress-entries');
      final list = response.data as List<dynamic>;
      return list
          .map((json) =>
              ChantierProgressEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetches alerts for the Suivi tab.
  /// GET /chantier/{id}/alerts
  Future<List<ChantierAlert>> getAlerts(int id) async {
    try {
      final response = await _dio.get('/chantier/$id/alerts');
      final list = response.data as List<dynamic>;
      return list
          .map((json) => ChantierAlert.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
