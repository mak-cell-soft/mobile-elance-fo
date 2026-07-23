import 'package:get/get.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../../../routes/app_routes.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _service = AuthService();

  final status = ViewStatus.initial.obs;
  final errorMessage = RxnString();

  String? get fullName => StorageService.instance.fullName;
  String? get enterpriseName => StorageService.instance.enterpriseName;

  Future<bool> login(String login, String password) async {
    if (login.trim().isEmpty || password.isEmpty) {
      errorMessage.value = 'Identifiant et mot de passe requis.';
      return false;
    }

    status.value = ViewStatus.loading;
    errorMessage.value = null;

    try {
      final result = await _service.login(login: login.trim(), password: password);

      if (!result.isSuccess || result.token == null) {
        status.value = ViewStatus.error;
        errorMessage.value = result.message ?? 'Échec de la connexion.';
        return false;
      }

      await StorageService.instance.saveSession(
        token: result.token!,
        fullName: result.fullname,
        enterpriseName: result.enterpriseName,
      );

      status.value = ViewStatus.success;
      return true;
    } on ApiException catch (e) {
      status.value = ViewStatus.error;
      errorMessage.value = e.message;
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.instance.clearSession();
    Get.offAllNamed(AppRoutes.login);
  }
}
