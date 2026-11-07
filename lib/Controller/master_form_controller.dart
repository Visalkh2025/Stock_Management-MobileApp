import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/master_list_controller.dart';
import 'package:stock_management/Model/master_data_models.dart';
import 'package:stock_management/Services/api_exception.dart';

/// Add/Edit form behind one Manage > `<thing>` list.
abstract class MasterFormController<T extends MasterRecord> extends GetxController {
  T? get original => Get.arguments as T?;

  bool get isEditing => original != null;

  final codeController = TextEditingController();
  final nameController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final isSaving = false.obs;
  final errorMessage = RxnString();

  /// The list this form belongs to (created on demand, like the other
  /// shared controllers).
  MasterListController<T> get list;

  /// Copies the record's extra fields into the subclass's text controllers.
  void fillFrom(T item);

  /// The subclass's extra fields for the request body. Use null for an empty
  /// optional field: it is left out when adding and sent as null (cleared)
  /// when editing.
  Map<String, dynamic> extraBody();

  @override
  void onInit() {
    super.onInit();
    final item = original;
    if (item != null) {
      codeController.text = item.code;
      nameController.text = item.name;
      fillFrom(item);
    }
  }

  String? requiredText(String? v) => (v == null || v.trim().isEmpty) ? 'validation_required'.tr : null;

  /// Codes are upper-cased and have no spaces, e.g. `WH-A`.
  String? codeValidator(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return 'validation_required'.tr;
    if (text.length > 50) return 'validation_code_too_long'.tr;
    if (text.contains(RegExp(r'\s'))) return 'validation_code_no_spaces'.tr;
    return null;
  }

  /// Trims [controller]'s text; null when empty.
  String? textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> save() async {
    errorMessage.value = null;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final body = <String, dynamic>{
      'name': nameController.text.trim(),
      ...extraBody(),
    };

    isSaving.value = true;
    try {
      final item = original;
      if (item == null) {
        body.removeWhere((_, v) => v == null);
        body['code'] = codeController.text.trim().toUpperCase();
        await list.crud.create(body);
      } else {
        await list.crud.update(item.id, body);
      }
      await list.load();
      Get.back();
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    codeController.dispose();
    nameController.dispose();
    super.onClose();
  }
}
