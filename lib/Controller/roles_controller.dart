import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/permissions_controller.dart';
import 'package:stock_management/Model/rbac_models.dart';

/// Security roles behind More > Roles & Permissions' "Roles" tab.
class RolesController extends GetxController {
  final _items = <RoleData>[
    const RoleData(
      name: 'SUPER_ADMIN',
      description: 'Full system administration and user access control',
      permissionCodes: ['product:view', 'product:create', 'product:update', 'product:certify'],
    ),
    const RoleData(
      name: 'Warehouse Staff',
      description: 'Warehouse stock receiving and intake management',
      permissionCodes: ['product:view', 'product:create'],
    ),
    const RoleData(
      name: 'STAFF',
      description: 'General staff operational permissions',
      permissionCodes: ['product:view'],
    ),
  ].obs;

  final searchQuery = ''.obs;

  int get count => _items.length;

  List<RoleData> get allItems => _items.toList();

  List<RoleData> get filteredItems {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return _items.toList();
    return _items.where((item) => item.name.toLowerCase().contains(query)).toList();
  }

  RoleData? findByName(String name) {
    for (final item in _items) {
      if (item.name == name) return item;
    }
    return null;
  }

  void setSearch(String value) => searchQuery.value = value;

  void openAdd() => Get.toNamed(Routes.roleForm);

  void openEdit(RoleData item) => Get.toNamed(Routes.roleForm, arguments: item);

  void openPermissions(RoleData item) => Get.toNamed(Routes.rolePermissions, arguments: item);

  void upsert(RoleData item, {RoleData? original}) {
    final index = original == null ? -1 : _items.indexOf(original);
    if (index == -1) {
      _items.insert(0, item);
    } else {
      _items[index] = item;
    }
  }

  void delete(RoleData item) => _items.remove(item);

  /// Quick-remove a single permission chip straight from the role card.
  void removePermission(RoleData role, String code) {
    final index = _items.indexOf(role);
    if (index == -1) return;
    _items[index] = role.copyWith(permissionCodes: role.permissionCodes.where((c) => c != code).toList());
  }

  /// Called by [RolePermissionsController.save] — replaces a role's whole
  /// permission set with what was checked on that screen.
  void setPermissions(RoleData role, List<String> codes) {
    final index = _items.indexOf(role);
    if (index == -1) return;
    _items[index] = role.copyWith(permissionCodes: codes);
  }

  /// Called by [PermissionsController.delete] when a permission code is
  /// removed from the catalog — keeps every role's permissionCodes from
  /// referencing a code that no longer exists.
  void removePermissionFromAllRoles(String code) {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].permissionCodes.contains(code)) {
        _items[i] = _items[i].copyWith(permissionCodes: _items[i].permissionCodes.where((c) => c != code).toList());
      }
    }
  }

  PermissionsController get permissions {
    if (!Get.isRegistered<PermissionsController>()) {
      Get.put(PermissionsController(), permanent: true);
    }
    return Get.find<PermissionsController>();
  }

  /// A role's chips need each code's full [PermissionData] (for the
  PermissionData permissionFor(String code) {
    for (final permission in permissions.allItems) {
      if (permission.code == code) return permission;
    }
    return PermissionData(code: code, category: '', description: '');
  }
}
