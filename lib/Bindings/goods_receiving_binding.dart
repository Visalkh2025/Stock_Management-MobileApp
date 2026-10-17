import 'package:get/get.dart';
import 'package:stock_management/Controller/goods_receiving_controller.dart';

class GoodsReceivingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GoodsReceivingController>(() => GoodsReceivingController());
  }
}
