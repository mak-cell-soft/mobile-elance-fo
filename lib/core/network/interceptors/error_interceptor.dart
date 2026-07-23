import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../storage/storage_service.dart';
import '../../../routes/app_routes.dart';

/// Centralised handling for the error cases every screen would otherwise
/// have to deal with individually: expired session, disabled tenant, and
/// generic server/network failures.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    if (statusCode == 401) {
      _handleUnauthorized();
    }

    handler.next(err);
  }

  void _handleUnauthorized() {
    final wasLoggedIn = StorageService.instance.isLoggedIn;
    if (!wasLoggedIn) return;

    StorageService.instance.clearSession();

    if (Get.currentRoute != AppRoutes.login) {
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        'Session expirée',
        'Veuillez vous reconnecter.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
