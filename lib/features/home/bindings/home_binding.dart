import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../controllers/home_controller.dart';

/// Binding class to register HomeController, AuthController, and NotificationController
/// for GetX dependency injection on the Home route.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<HomeController>(() => HomeController());
    if (!Get.isRegistered<NotificationController>()) {
      Get.put<NotificationController>(NotificationController(), permanent: true);
    }
  }
}
