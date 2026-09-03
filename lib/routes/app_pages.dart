import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../core/storage/storage_service.dart';
import '../features/articles/bindings/articles_binding.dart';
import '../features/articles/views/articles_list_view.dart';
import '../features/auth/bindings/auth_binding.dart';
import '../features/auth/views/login_view.dart';
import '../features/chantiers/bindings/chantiers_binding.dart';
import '../features/chantiers/views/chantier_detail_view.dart';
import '../features/chantiers/views/chantiers_list_view.dart';
import '../features/customers/bindings/customers_binding.dart';
import '../features/customers/views/customers_list_view.dart';
import '../features/home/bindings/home_binding.dart';
import '../features/home/views/home_view.dart';
import '../features/notifications/bindings/notifications_binding.dart';
import '../features/notifications/views/notifications_view.dart';
import '../features/settings/bindings/settings_binding.dart';
import '../features/settings/views/settings_view.dart';
import '../features/splash/views/splash_view.dart';
import '../features/tenant/bindings/tenant_binding.dart';
import '../features/tenant/views/tenant_selection_view.dart';
import 'app_routes.dart';

abstract class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),
    GetPage(
      name: AppRoutes.tenantSelection,
      page: () => const TenantSelectionView(),
      binding: TenantBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.articles,
      page: () => const ArticlesListView(),
      binding: ArticlesBinding(),
    ),
    GetPage(
      name: AppRoutes.customers,
      page: () => const CustomersListView(),
      binding: CustomersBinding(),
    ),
    GetPage(
      name: AppRoutes.chantiers,
      page: () => const ChantiersListView(),
      binding: ChantiersBinding(),
      middlewares: [ChantierGuardMiddleware()],
    ),
    GetPage(
      name: AppRoutes.chantierDetail,
      page: () => const ChantierDetailView(),
      binding: ChantiersBinding(),
      middlewares: [ChantierGuardMiddleware()],
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
    ),
  ];
}

/// Route guard redirecting to Home if the active tenant does not have the Chantier module.
class ChantierGuardMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!StorageService.instance.hasChantierModule) {
      return const RouteSettings(name: AppRoutes.home);
    }
    return null;
  }
}
