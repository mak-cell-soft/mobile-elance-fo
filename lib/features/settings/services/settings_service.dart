import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/app_variable.dart';

/// Service responsible for fetching and updating system settings and AppVariables.
class SettingsService {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /AppVariable/getall/{nature}
  Future<List<AppVariable>> fetchVariables(String nature) async {
    try {
      final response = await _dio.get('AppVariable/getall/$nature');
      final data = response.data as List<dynamic>;
      return data
          .map((json) => AppVariable.fromJson(json as Map<String, dynamic>))
          .where((v) => !(v.isDeleted ?? false))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /AppVariable/daily-ceiling
  Future<void> upsertDailyCeiling(String date, String amount) async {
    try {
      await _dio.post(
        'AppVariable/daily-ceiling',
        data: {
          'name': date,
          'value': amount,
          'nature': 'DailyInvoiceCeiling',
          'isactive': true,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /AppVariable/Add
  Future<void> addVariable(Map<String, dynamic> model) async {
    try {
      await _dio.post('AppVariable/Add', data: model);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PUT /AppVariable/{id}
  Future<void> updateVariable(int id, Map<String, dynamic> model) async {
    try {
      await _dio.put('AppVariable/$id', data: model);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE /AppVariable/{id}
  Future<void> deleteVariable(int id) async {
    try {
      await _dio.delete('AppVariable/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
