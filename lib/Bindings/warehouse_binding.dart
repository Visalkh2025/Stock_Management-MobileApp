import 'package:get/get.dart';
import 'package:stock_management/Controller/warehouse_controller.dart';

class WarehouseBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<WarehouseController>()) {
      Get.put<WarehouseController>(WarehouseController(), permanent: true);
    }
  }
}
