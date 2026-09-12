import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/receipt_document.dart';
import '../models/supplier.dart';

/// NOTE: Service layer communicating with backend .NET DocumentController & CounterpartController.
/// Directly mirrors document.service.ts and useDocumentsByTypeFiltered in fo-acya-app/elance-app.ui.
class ReceiptService {
  final Dio _dio = ApiClient.instance.dio;

  /// Fetches Bon de Réception (BR) documents filtered by accounting period.
  /// C# Endpoint: POST /api/Document/_typefiltered
  /// Payload: { "typeDoc": 2, "month": month, "year": year, "day": day }
  /// - typeDoc: 2 maps to C# DocumentTypes.supplierReceipt
  /// - month: 1..12
  /// - year: e.g. 2026
  /// - day: 0 for all days of the month, or 1..31 for specific day
  Future<List<ReceiptDocument>> fetchReceiptsFiltered({
    required int month,
    required int year,
    int day = 0,
  }) async {
    try {
      final payload = {
        'typeDoc': 2, // DocumentTypes.supplierReceipt
        'month': month,
        'year': year,
        'day': day,
      };

      final response = await _dio.post('Document/_typefiltered', data: payload);
      final data = response.data as List<dynamic>;

      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => ReceiptDocument.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetches full list of counterpart suppliers for client-side drop-down filtering.
  /// C# Endpoint: GET /api/Counterpart/getall/Supplier
  Future<List<SupplierItem>> fetchSuppliers() async {
    try {
      final response = await _dio.get('Counterpart/getall/Supplier');
      final data = response.data as List<dynamic>;

      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => SupplierItem.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
