import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/env.dart';
import 'core/config/tenant_build_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/tenant_theme.dart';
import 'core/theme/theme_service.dart';
import 'features/tenant/models/tenant_config.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

/// Default entry point (`flutter run` with no --target) runs development.
void main() => bootstrap(Flavor.development);

/// Shared bootstrap invoked by each flavor's entry point
/// (main_development.dart, main_preprod.dart, main_production.dart).
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.init(flavor);
  await StorageService.ensureInitialized();

  // Initialize French locale date symbols for DateFormat (prevents LocaleDataException)
  try {
    await initializeDateFormatting('fr_FR', null);
  } catch (_) {}

  // Load tenant configuration: checks assets/tenant_config.json,
  // assets/tenants/{tenantId}/config.json, or compile-time build config
  final activeConfig = await TenantConfig.loadActiveConfig();
  await StorageService.instance.saveTenantSlug(activeConfig.tenantId ?? TenantBuildConfig.tenantId);
  await StorageService.instance.saveTenantConfig(activeConfig.toJson());
  ApiClient.instance.setBaseUrl(activeConfig.baseUrl ?? TenantBuildConfig.baseUrl);

  ThemeService.instance.init();
  runApp(WoodApp(tenantConfig: activeConfig));
}

class WoodApp extends StatelessWidget {
  final TenantConfig? tenantConfig;

  const WoodApp({super.key, this.tenantConfig});

  @override
  Widget build(BuildContext context) {
    final cfg = tenantConfig ??
        (StorageService.instance.tenantConfig != null
            ? TenantConfig.fromJson(StorageService.instance.tenantConfig!)
            : TenantConfig.fromBuildConfig());
    final primaryColor = cfg.primaryColor ?? TenantBuildConfig.primaryColor;
    final secondaryColor = cfg.secondaryColor ?? TenantBuildConfig.secondaryColor;
    final appTitle = cfg.companyName ?? cfg.appName ?? TenantBuildConfig.companyName;

    return GetMaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: !EnvConfig.isProduction,
      theme: TenantTheme.buildLight(
        primaryColorHex: primaryColor,
        secondaryColorHex: secondaryColor,
      ),
      darkTheme: TenantTheme.buildDark(
        primaryColorHex: primaryColor,
        secondaryColorHex: secondaryColor,
      ),
      themeMode: ThemeService.instance.themeMode,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}
