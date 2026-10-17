import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/brand_controller.dart';
import 'package:stock_management/Controller/master_form_controller.dart';
import 'package:stock_management/Model/master_data_models.dart';

/// Add/Edit form behind Manage > Brands — see [MasterFormController].
class BrandFormController extends MasterFormController<BrandData> {
  final descriptionController = TextEditingController();

  @override
  BrandController get list {
    if (!Get.isRegistered<BrandController>()) {
      Get.put(BrandController(), permanent: true);
    }
    return Get.find<BrandController>();
  }

  @override
  void fillFrom(BrandData item) {
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
