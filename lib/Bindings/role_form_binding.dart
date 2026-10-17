import 'package:get/get.dart';
import 'package:stock_management/Controller/role_form_controller.dart';

class RoleFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RoleFormController>(() => RoleFormController());
  }
}
