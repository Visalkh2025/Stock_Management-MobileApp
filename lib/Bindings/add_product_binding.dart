import 'package:get/get.dart';
import 'package:stock_management/Controller/add_product_controller.dart';

class AddProductBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddProductController>(() => AddProductController());
  }
}
