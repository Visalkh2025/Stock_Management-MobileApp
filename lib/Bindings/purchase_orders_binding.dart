import 'package:get/get.dart';
import 'package:stock_management/Controller/purchase_orders_controller.dart';

class PurchaseOrdersBinding extends Bindings {
  @override
  void dependencies() {
    // Permanent so the count badge on More survives leaving this screen.
    if (!Get.isRegistered<PurchaseOrdersController>()) {
      Get.put<PurchaseOrdersController>(PurchaseOrdersController(), permanent: true);
    }
  }
}
