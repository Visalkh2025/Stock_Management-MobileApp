import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/permissions_controller.dart';
import 'package:stock_management/Model/rbac_models.dart';

/// Add/Edit form behind Roles & Permissions > Permissions. Get.arguments
/// is the [PermissionData] being edited, or null when adding a new one.
class PermissionFormController extends GetxController {
  PermissionData? get _original => Get.arguments as PermissionData?;

  bool get isEditing => _original != null;

  final codeController = TextEditingController();
  final categoryController = TextEditingController();
  final descriptionController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    final original = _original;
    if (original != null) {
      codeController.text = original.code;
      categoryController.text = original.category;
      descriptionController.text = original.description;
    }
  }

  PermissionsController get _permissions {
    if (!Get.isRegistered<PermissionsController>()) {
      Get.put(PermissionsController(), permanent: true);
    }
    return Get.find<PermissionsController>();
  }

  void save() {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final item = PermissionData(
      code: codeController.text.trim(),
      category: categoryController.text.trim(),
      description: descriptionController.text.trim(),
    );
    _permissions.upsert(item, original: _original);
    Get.back();
  }

  @override
  void onClose() {
    codeController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
