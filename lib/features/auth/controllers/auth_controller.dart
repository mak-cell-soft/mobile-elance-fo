import 'package:get/get.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../../../routes/app_routes.dart';
import '../../tenant/models/tenant_config.dart';
import '../../tenant/services/enterprise_service.dart';
import '../../tenant/services/tenant_service.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _service = AuthService();
  final TenantService _tenantService = TenantService();
  final bool enableRemoteSync;

  AuthController({this.enableRemoteSync = true});

  final status = ViewStatus.initial.obs;
  final errorMessage = RxnString();

  /// Reactive tenant configuration used by LoginView for dynamic logo & branding.
  /// Mirrors useTenantStore in fo-acya-app/elance-app.ui.
  final Rxn<TenantConfig> tenantConfig = Rxn<TenantConfig>();

  String? get fullName => StorageService.instance.fullName;
  String? get enterpriseName => StorageService.instance.enterpriseName;

  @override
  void onInit() {
    super.onInit();
    loadTenantConfig();
  }

  /// Loads stored tenant config immediately for instantaneous UI rendering,
  /// then asynchronously fetches fresh branding from GET /api/enterprise/config.
  Future<void> loadTenantConfig() async {
    if (Get.testMode && !enableRemoteSync) return;

    // 1. Immediate local load to prevent visual pop-in
    if (tenantConfig.value == null) {
      final storedJson = StorageService.instance.tenantConfig;
      if (storedJson != null) {
        tenantConfig.value = TenantConfig.fromJson(storedJson);
      } else {
        final active = await TenantConfig.loadActiveConfig();
        if (tenantConfig.value == null) {
          tenantConfig.value = active;
        }
      }
    }

    // 2. Refresh dynamically from remote backend API if slug is available
    if (enableRemoteSync && !Get.testMode) {
      final slug = StorageService.instance.tenantSlug ?? tenantConfig.value?.tenantId;
      if (slug != null && slug.trim().isNotEmpty) {
        try {
          final remote = await _tenantService.fetchConfig(slug);
        // NOTE: Merge remote branding while preserving existing local asset metadata
        final current = tenantConfig.value;
        final merged = TenantConfig(
          tenantId: remote.tenantId ?? slug,
          companyName: remote.companyName ?? current?.companyName,
          appName: remote.appName ?? current?.appName,
          packageName: remote.packageName ?? current?.packageName,
          name: remote.name ?? current?.name,
          logo: current?.logo,
          logoUrl: remote.logoUrl,
          faviconUrl: remote.faviconUrl ?? current?.faviconUrl,
          primaryColor: remote.primaryColor ?? current?.primaryColor,
          secondaryColor: remote.secondaryColor ?? current?.secondaryColor,
          baseUrl: remote.baseUrl ?? current?.baseUrl,
          environment: remote.environment ?? current?.environment,
          supportedLocales: remote.supportedLocales ?? current?.supportedLocales,
          assetsPath: remote.assetsPath ?? current?.assetsPath,
          language: remote.language ?? current?.language,
          currency: remote.currency ?? current?.currency,
          status: remote.status ?? current?.status,
          hasChantierModule: remote.hasChantierModule,
          isManagingConstructions: remote.isManagingConstructions,
        );

        tenantConfig.value = merged;
        await StorageService.instance.saveTenantConfig(merged.toJson());
        } catch (_) {
          // Fallback: Gracefully retain local stored configuration when offline or on network error
        }
      }
    }
  }

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

      // Fetch fresh enterprise info (feature flags such as ismanagingconstructions)
      final entId = StorageService.instance.enterpriseId;
      if (entId != null) {
        try {
          final ent = await EnterpriseService().fetchEnterprise(entId);
          if (ent != null) {
            await StorageService.instance.saveEnterpriseInfo(ent);
          }
        } catch (_) {
          // Gracefully continue; JWT claims remain the primary fallback
        }
      }

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
