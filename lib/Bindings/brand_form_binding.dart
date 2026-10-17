import 'package:get/get.dart';
import 'package:stock_management/Controller/brand_form_controller.dart';

class BrandFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BrandFormController>(() => BrandFormController());
  }
}
