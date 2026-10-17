import 'package:get/get.dart';
import 'package:stock_management/Controller/purchase_order_detail_controller.dart';

class PurchaseOrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PurchaseOrderDetailController>(() => PurchaseOrderDetailController());
  }
}
