import 'package:get/get.dart';
import '../features/articles/bindings/articles_binding.dart';
import '../features/articles/views/articles_list_view.dart';
import '../features/auth/bindings/auth_binding.dart';
import '../features/auth/views/login_view.dart';
import '../features/home/views/home_view.dart';
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
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.articles,
      page: () => const ArticlesListView(),
      binding: ArticlesBinding(),
    ),
  ];
}
