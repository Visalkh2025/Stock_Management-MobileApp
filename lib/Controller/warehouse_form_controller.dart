import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/warehouse_controller.dart';
import 'package:stock_management/Controller/master_form_controller.dart';
import 'package:stock_management/Model/master_data_models.dart';

/// Add/Edit form behind Manage > Warehouses — see [MasterFormController]. The location is the warehouse's address on the server.
class WarehouseFormController extends MasterFormController<WarehouseData> {
  final locationController = TextEditingController();

  @override
  WarehouseController get list {
    if (!Get.isRegistered<WarehouseController>()) {
      Get.put(WarehouseController(), permanent: true);
    }
    return Get.find<WarehouseController>();
  }

  @override
  void fillFrom(WarehouseData item) {
    locationController.text = item.location ?? '';
  }

  @override
  Map<String, dynamic> extraBody() => {
        'address': textOrNull(locationController),
      };

  @override
  void onClose() {
    locationController.dispose();
    super.onClose();
  }
}
