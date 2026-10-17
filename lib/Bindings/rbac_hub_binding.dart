import 'package:get/get.dart';
import 'package:stock_management/Controller/permissions_controller.dart';
import 'package:stock_management/Controller/rbac_hub_controller.dart';
import 'package:stock_management/Controller/roles_controller.dart';

/// More > Roles & Permissions routes here (Routes.rolesPermissions).
/// Puts both data controllers up front (permanent, guarded) so switching
/// tabs never re-triggers a cold Get.put mid-build.
class RbacHubBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RbacHubController>(() => RbacHubController());
    if (!Get.isRegistered<RolesController>()) {
      Get.put<RolesController>(RolesController(), permanent: true);
    }
    if (!Get.isRegistered<PermissionsController>()) {
      Get.put<PermissionsController>(PermissionsController(), permanent: true);
    }
  }
}
