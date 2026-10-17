import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/roles_controller.dart';
import 'package:stock_management/Model/rbac_models.dart';

/// The system-wide permission catalog behind More > Roles & Permissions'
/// "Permissions" tab — defining a code here doesn't grant it to anyone;
/// [RolesController] is what assigns catalog codes to a role. Same
/// list/search/upsert/delete shape as CategoryController.
class PermissionsController extends GetxController {
  final _items = <PermissionData>[
    const PermissionData(code: 'product:view', category: 'product', description: 'View inventory items and stock requests'),
    const PermissionData(code: 'product:create', category: 'product', description: 'Create and draft product intake requests'),
    const PermissionData(code: 'product:update', category: 'product', description: 'Update product catalogs and variant details'),
    const PermissionData(code: 'product:certify', category: 'product', description: 'Certify and approve warehouse intake requests'),
  ].obs;

  final searchQuery = ''.obs;

  int get count => _items.length;

  List<PermissionData> get allItems => _items.toList();

  List<PermissionData> get filteredItems {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return _items.toList();
    return _items.where((item) {
      return item.code.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  }

  /// [filteredItems] grouped by category, in first-seen order — backs the
  /// grouped card list (the mobile replacement for the web's separate
  /// "Category Matrix" tab; see PermissionsScreen).
  Map<String, List<PermissionData>> get groupedByCategory {
    final grouped = <String, List<PermissionData>>{};
    for (final item in filteredItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  void setSearch(String value) => searchQuery.value = value;

  void openAdd() => Get.toNamed(Routes.permissionForm);

  void openEdit(PermissionData item) => Get.toNamed(Routes.permissionForm, arguments: item);

  void upsert(PermissionData item, {PermissionData? original}) {
    final index = original == null ? -1 : _items.indexOf(original);
    if (index == -1) {
      _items.insert(0, item);
    } else {
      _items[index] = item;
    }
  }

  RolesController get _roles {
    if (!Get.isRegistered<RolesController>()) {
      Get.put(RolesController(), permanent: true);
    }
    return Get.find<RolesController>();
  }

  /// Deleting a permission code also strips it from every role that
  /// granted it — otherwise a role would keep referencing a code that no
  /// longer exists in the catalog.
  void delete(PermissionData item) {
    _items.remove(item);
    _roles.removePermissionFromAllRoles(item.code);
  }
}
