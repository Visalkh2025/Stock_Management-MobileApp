import 'package:get/get.dart';
import 'package:stock_management/Controller/manage_controller.dart';

class ManageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManageController>(() => ManageController());
  }
}
