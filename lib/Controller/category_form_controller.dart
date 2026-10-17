import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/category_controller.dart';
import 'package:stock_management/Controller/master_form_controller.dart';
import 'package:stock_management/Model/master_data_models.dart';

/// Add/Edit form behind Manage > Categories — see [MasterFormController].
class CategoryFormController extends MasterFormController<CategoryData> {
  final descriptionController = TextEditingController();

  @override
  CategoryController get list {
    if (!Get.isRegistered<CategoryController>()) {
      Get.put(CategoryController(), permanent: true);
    }
    return Get.find<CategoryController>();
  }

  @override
  void fillFrom(CategoryData item) {
    descriptionController.text = item.description ?? '';
  }

  @override
  Map<String, dynamic> extraBody() => {
        'description': textOrNull(descriptionController),
      };

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }
}
