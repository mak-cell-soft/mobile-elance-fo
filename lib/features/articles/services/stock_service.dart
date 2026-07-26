import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/stock.dart';

/// Service responsible for fetching stock data from backend endpoints.
class StockService {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /Stock returns all stock records for the active tenant.
  Future<List<Stock>> fetchAll() async {
    try {
      final response = await _dio.get('Stock');
      final data = response.data as List<dynamic>;
      return data
          .map((json) => Stock.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
