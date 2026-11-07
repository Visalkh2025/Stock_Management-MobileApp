import 'package:get/get.dart';
import 'package:stock_management/Controller/edit_product_controller.dart';

class EditProductBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditProductController>(() => EditProductController());
  }
}
