import 'package:get/get.dart';
import 'package:stock_management/Controller/warehouse_form_controller.dart';

class WarehouseFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WarehouseFormController>(() => WarehouseFormController());
  }
}
