import 'package:get/get.dart';
import '../controllers/production_controller.dart';
import '../controllers/production_personnel_controller.dart';

/// Dependency injection binding for the Production module.
/// Uses [Get.lazyPut] to avoid permanent registrations or memory leaks when exiting the module.
class ProductionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductionController>(() => ProductionController());
    Get.lazyPut<ProductionPersonnelController>(() => ProductionPersonnelController());
  }
}
