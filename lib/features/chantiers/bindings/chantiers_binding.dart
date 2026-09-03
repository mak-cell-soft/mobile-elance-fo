import 'package:get/get.dart';
import '../controllers/chantier_detail_controller.dart';
import '../controllers/chantiers_list_controller.dart';

/// Dependency injection binding for Chantiers feature.
class ChantiersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChantiersListController>(() => ChantiersListController());
    Get.lazyPut<ChantierDetailController>(() => ChantierDetailController());
  }
}
