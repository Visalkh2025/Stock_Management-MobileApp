import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/warehouse_controller.dart';
import 'package:stock_management/Controller/master_form_controller.dart';
import 'package:stock_management/Model/master_data_models.dart';

/// Add/Edit form behind Manage > Warehouses — see [MasterFormController]. The location is the warehouse's address on the server.
class WarehouseFormController extends MasterFormController<WarehouseData> {
  final locationController = TextEditingController();
  final capacityController = TextEditingController();

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
    final cap = item.capacity;
    capacityController.text = cap == null ? '' : (cap == cap.roundToDouble() ? cap.round().toString() : '$cap');
  }

  @override
  Map<String, dynamic> extraBody() => {
        'address': textOrNull(locationController),
        // Empty = no limit (sent as null so editing can clear an old limit).
        'capacity': double.tryParse(capacityController.text.trim()),
      };

  /// Optional; a number above 0.
  String? capacityValidator(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return null;
    final n = double.tryParse(text);
    return (n == null || n <= 0) ? 'validation_capacity_invalid'.tr : null;
  }

  @override
  void onClose() {
    locationController.dispose();
    capacityController.dispose();
    super.onClose();
  }
}
