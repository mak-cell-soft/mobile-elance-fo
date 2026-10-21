import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/production_order.dart';
import '../models/production_personnel_models.dart';

/// Service interfacing with the backend /api/production REST endpoints.
/// Strictly read-only operations for Production Dashboard, Order Details, and Personnel & Prestations.
/// Reuses centralized [ApiClient.instance.dio] with automated tenant slug and JWT auth interceptors.
class ProductionService {
  final Dio _dio = ApiClient.instance.dio;

  /// Fetches all production orders with optional status, salesSiteId, and search filters.
  /// Backend Endpoint: GET /api/production
  /// C# Controller: ProductionController.GetAll([FromQuery] ProductionStatus? status, [FromQuery] int? salesSiteId, [FromQuery] string? search)
  Future<List<ProductionOrder>> fetchAll({
    ProductionStatus? status,
    int? salesSiteId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status.toInt;
      }
      if (salesSiteId != null) {
        queryParams['salesSiteId'] = salesSiteId;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      // NOTE: Using 'production' endpoint relative to ApiClient's baseUrl (e.g. https://domain/api/)
      final response = await _dio.get(
        'production',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((json) => ProductionOrder.fromJson(json))
            .toList();
      }
      return <ProductionOrder>[];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetches detailed production order by ID, including nested fabrication steps.
  /// Backend Endpoint: GET /api/production/{id}
  /// C# Controller: ProductionController.GetById(int id)
  Future<ProductionOrder> fetchById(int id) async {
    try {
      final response = await _dio.get('production/$id');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ProductionOrder.fromJson(data);
      }
      throw ApiException(
        type: ApiErrorType.unknown,
        message: 'Format de réponse invalide pour l\'ordre #$id',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetches calculated monthly employee payable summary for production.
  /// Backend Endpoint: GET /api/production/payables/monthly?year={year}&month={month}
  /// C# Controller: ProductionController.GetMonthlyPayableSummary(int year, int month)
  Future<MonthlyEmployeePayableSummary> fetchMonthlyPayableSummary({
    required int year,
    required int month,
  }) async {
    try {
      final response = await _dio.get(
        'production/payables/monthly',
        queryParameters: {
          'year': year,
          'month': month,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return MonthlyEmployeePayableSummary.fromJson(data);
      }
      throw ApiException(
        type: ApiErrorType.unknown,
        message: 'Format de réponse invalide pour le récapitulatif mensuel',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetches standalone other work prestations outside fabrication orders.
  /// Backend Endpoint: GET /api/production/other-work
  /// C# Controller: ProductionController.GetOtherWorkEntries(DateTime? startDate, DateTime? endDate, int? personId)
  Future<List<ProductionOtherWorkEntry>> fetchOtherWorkEntries({
    DateTime? startDate,
    DateTime? endDate,
    int? personId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T').first;
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T').first;
      }
      if (personId != null && personId > 0) {
        queryParams['personId'] = personId;
      }

      final response = await _dio.get(
        'production/other-work',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((json) => ProductionOtherWorkEntry.fromJson(json))
            .toList();
      }
      return <ProductionOtherWorkEntry>[];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
