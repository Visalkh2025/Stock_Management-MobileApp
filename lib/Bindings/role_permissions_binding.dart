import 'package:get/get.dart';
import 'package:stock_management/Controller/role_permissions_controller.dart';

class RolePermissionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RolePermissionsController>(() => RolePermissionsController());
  }
}
