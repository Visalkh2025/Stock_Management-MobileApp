import 'package:get/get.dart';
import 'package:stock_management/Controller/category_controller.dart';

class CategoryBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CategoryController>()) {
      Get.put<CategoryController>(CategoryController(), permanent: true);
    }
  }
}
