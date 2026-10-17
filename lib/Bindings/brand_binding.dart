import 'package:get/get.dart';
import 'package:stock_management/Controller/brand_controller.dart';

class BrandBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<BrandController>()) {
      Get.put<BrandController>(BrandController(), permanent: true);
    }
  }
}
