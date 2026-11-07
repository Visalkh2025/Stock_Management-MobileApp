import 'package:get/get.dart';
import 'package:stock_management/Controller/permissions_controller.dart';
import 'package:stock_management/Controller/roles_controller.dart';
import 'package:stock_management/Model/rbac_models.dart';

/// The full-catalog checklist behind a role card's "Permissions" button.
class RolePermissionsController extends GetxController {
  RoleData get role => Get.arguments as RoleData;

  final selectedCodes = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    selectedCodes.addAll(role.permissionCodes);
  }

  PermissionsController get _permissions {
    if (!Get.isRegistered<PermissionsController>()) {
      Get.put(PermissionsController(), permanent: true);
    }
    return Get.find<PermissionsController>();
  }

  RolesController get _roles {
    if (!Get.isRegistered<RolesController>()) {
      Get.put(RolesController(), permanent: true);
    }
    return Get.find<RolesController>();
  }

  Map<String, List<PermissionData>> get groupedByCategory {
    final grouped = <String, List<PermissionData>>{};
    for (final item in _permissions.allItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  bool isSelected(String code) => selectedCodes.contains(code);

  void toggle(String code) {
    if (selectedCodes.contains(code)) {
      selectedCodes.remove(code);
    } else {
      selectedCodes.add(code);
    }
  }

  void save() {
    _roles.setPermissions(role, selectedCodes.toList());
    Get.back();
  }
}
