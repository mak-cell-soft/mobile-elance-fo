import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/customer.dart';

/// Service responsible for fetching counterpart customers from backend.
class CustomerService {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /CounterPart/GetAll/Customer
  Future<List<Customer>> fetchAll() async {
    try {
      final response = await _dio.get('CounterPart/GetAll/Customer');
      final data = response.data as List<dynamic>;
      return data
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .where((c) => !(c.isDeleted ?? false))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
