import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

/// Service to fetch enterprise configuration from the WoodApp backend API.
/// Sourced from GET /api/enterprise/getbyid/{id}.
/// Mirrors enterpriseService in fo-acya-app/elance-app.ui.
class EnterpriseService {
  final Dio _dio = ApiClient.instance.dio;

  /// Fetches enterprise details by ID (including ismanagingconstructions flag).
  Future<Map<String, dynamic>?> fetchEnterprise(int enterpriseId) async {
    try {
      final response = await _dio.get('enterprise/getbyid/$enterpriseId');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException {
      // Don't crash if enterprise fetch fails; fallback will rely on JWT claim
      return null;
    } catch (_) {
      return null;
    }
  }
}
