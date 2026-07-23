import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/tenant_config.dart';

class TenantService {
  final Dio _dio = ApiClient.instance.dio;

  /// Validates a tenant slug and fetches its branding in one call.
  /// The slug isn't stored yet at this point, so it's passed explicitly
  /// as a header instead of relying on AuthInterceptor.
  Future<TenantConfig> fetchConfig(String slug) async {
    try {
      final response = await _dio.get(
        'enterprise/config',
        options: Options(headers: {'X-Tenant-Slug': slug}),
      );
      return TenantConfig.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
