import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/config/env.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/tenant_theme.dart';
import 'core/theme/theme_service.dart';
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
  ThemeService.instance.init();
  runApp(const WoodApp());
}

class WoodApp extends StatelessWidget {
  const WoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'WoodApp',
      debugShowCheckedModeBanner: !EnvConfig.isProduction,
      theme: TenantTheme.buildLight(),
      darkTheme: TenantTheme.buildDark(),
      themeMode: ThemeService.instance.themeMode,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}
