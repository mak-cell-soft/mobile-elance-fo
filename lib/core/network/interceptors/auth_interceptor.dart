import 'package:dio/dio.dart';
import '../../storage/storage_service.dart';

/// Attaches the JWT and the currently selected tenant slug to every request.
///
/// The backend cross-validates the X-Tenant-Slug header against the
/// tenant_slug claim baked into the JWT, so both must always travel together.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = StorageService.instance.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    final tenantSlug = StorageService.instance.tenantSlug;
    if (tenantSlug != null && tenantSlug.isNotEmpty) {
      options.headers['X-Tenant-Slug'] = tenantSlug;
    }

    handler.next(options);
  }
}
