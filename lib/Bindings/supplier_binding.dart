import 'package:get/get.dart';
import 'package:stock_management/Controller/supplier_controller.dart';

class SupplierBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupplierController>()) {
      Get.put<SupplierController>(SupplierController(), permanent: true);
    }
  }
}
