import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/tenant_config.dart';

class TenantService {
  final Dio _dio = ApiClient.instance.dio;

  /// Validates a tenant slug and fetches its branding in one call.
  /// Sourced from GET /api/enterprise/config on the backend.
  /// Mirrors TenantProvider.tsx in fo-acya-app/elance-app.ui.
  Future<TenantConfig> fetchConfig(String slug) async {
    try {
      final response = await _dio.get(
        'enterprise/config',
        options: Options(headers: {'X-Tenant-Slug': slug}),
      );
      // NOTE: The C# backend EnterpriseController.GetConfig() returns branding DTO without tenantId;
      // we attach the queried slug here to preserve tenant identity in the model.
      final data = Map<String, dynamic>.from(response.data as Map);
      data['tenantId'] ??= slug;
      return TenantConfig.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
