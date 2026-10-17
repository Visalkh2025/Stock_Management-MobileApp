import 'package:get/get.dart';
import 'package:stock_management/Controller/permission_form_controller.dart';

class PermissionFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PermissionFormController>(() => PermissionFormController());
  }
}
