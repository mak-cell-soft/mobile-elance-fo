import 'package:get/get.dart';
import '../../../core/config/tenant_build_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/tenant_theme.dart';
import '../../../core/theme/theme_service.dart';
import '../../../core/utils/view_status.dart';
import '../../../routes/app_routes.dart';
import '../models/tenant_config.dart';
import '../services/tenant_service.dart';

class TenantController extends GetxController {
  final TenantService _service = TenantService();

  final status = ViewStatus.initial.obs;
  final errorMessage = RxnString();
  final Rxn<TenantConfig> config = Rxn<TenantConfig>();
  final slug = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final remembered = StorageService.instance.tenantSlug;
    if (remembered != null) slug.value = remembered;

    final storedConfig = StorageService.instance.tenantConfig;
    if (storedConfig != null) {
      config.value = TenantConfig.fromJson(storedConfig);
      _applyTheme(config.value!);
    }
  }

  Future<bool> selectTenant(String rawSlug) async {
    final normalized = rawSlug.trim().toLowerCase();
    if (normalized.isEmpty) {
      errorMessage.value = 'Veuillez saisir le nom de votre entreprise.';
      return false;
    }

    status.value = ViewStatus.loading;
    errorMessage.value = null;

    try {
      final result = await _service.fetchConfig(normalized);

      if (!result.isActive) {
        status.value = ViewStatus.error;
        errorMessage.value = result.status == 'Suspended'
            ? 'Ce compte est suspendu. Contactez votre administrateur.'
            : "L'abonnement de cette entreprise a expiré.";
        return false;
      }

      await StorageService.instance.saveTenantSlug(normalized);
      await StorageService.instance.saveTenantConfig(result.toJson());
      config.value = result;
      slug.value = normalized;
      _applyTheme(result);

      status.value = ViewStatus.success;
      return true;
    } on ApiException catch (e) {
      status.value = ViewStatus.error;
      errorMessage.value = e.type == ApiErrorType.notFound
          ? 'Aucune entreprise ne correspond à ce nom.'
          : e.message;
      return false;
    }
  }

  void _applyTheme(TenantConfig cfg) {
    final themeData = ThemeService.instance.isDarkMode
        ? TenantTheme.buildDark(
            primaryColorHex: cfg.primaryColor,
            secondaryColorHex: cfg.secondaryColor,
          )
        : TenantTheme.buildLight(
            primaryColorHex: cfg.primaryColor,
            secondaryColorHex: cfg.secondaryColor,
          );
    Get.changeTheme(themeData);
  }

  void changeTenant() {
    if (TenantBuildConfig.isEmbedded) {
      // Pre-configured tenant apps are locked to their company app.
      return;
    }
    StorageService.instance.clearTenant();
    StorageService.instance.clearSession();
    config.value = null;
    slug.value = '';
    Get.offAllNamed(AppRoutes.tenantSelection);
  }
}
