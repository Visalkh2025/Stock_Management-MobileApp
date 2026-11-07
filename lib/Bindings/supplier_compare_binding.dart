import 'package:get/get.dart';
import 'package:stock_management/Controller/supplier_compare_controller.dart';

class SupplierCompareBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupplierCompareController>(() => SupplierCompareController());
  }
}
