import 'package:get/get.dart';
import '../controllers/receipts_controller.dart';
import '../services/receipt_service.dart';

/// NOTE: GetX binding registering the dependencies required by the
/// Bons de Réception (BR) feature view.
class ReceiptsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiptService>(() => ReceiptService());
    Get.lazyPut<ReceiptsController>(
      () => ReceiptsController(service: Get.find<ReceiptService>()),
    );
  }
}
