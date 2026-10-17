import 'package:get/get.dart';
import 'package:stock_management/Controller/purchase_order_form_controller.dart';

class PurchaseOrderFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PurchaseOrderFormController>(() => PurchaseOrderFormController());
  }
}
