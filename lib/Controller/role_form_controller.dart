import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/roles_controller.dart';
import 'package:stock_management/Model/rbac_models.dart';

/// Add/Edit form behind Roles & Permissions > Roles.
class RoleFormController extends GetxController {
  RoleData? get _original => Get.arguments as RoleData?;

  bool get isEditing => _original != null;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    final original = _original;
    if (original != null) {
      nameController.text = original.name;
      descriptionController.text = original.description;
    }
  }

  RolesController get _roles {
    if (!Get.isRegistered<RolesController>()) {
      Get.put(RolesController(), permanent: true);
    }
    return Get.find<RolesController>();
  }

  void save() {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final original = _original;
    final item = RoleData(
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      // A new role starts with no permissions — granted afterwards via
      // the role card's "Permissions" button. Editing keeps whatever the
      // role already had.
      permissionCodes: original?.permissionCodes ?? const [],
    );
    _roles.upsert(item, original: original);
    Get.back();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
