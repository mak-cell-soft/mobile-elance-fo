import 'package:get/get.dart';
import '../controllers/tenant_controller.dart';

class TenantBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TenantController>(() => TenantController(), fenix: true);
  }
}
