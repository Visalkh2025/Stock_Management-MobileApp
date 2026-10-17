import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/supplier_controller.dart';
import 'package:stock_management/Controller/master_form_controller.dart';
import 'package:stock_management/Model/master_data_models.dart';

/// Add/Edit form behind Manage > Suppliers — see [MasterFormController].
class SupplierFormController extends MasterFormController<SupplierData> {
  final contactPersonController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();

  @override
  SupplierController get list {
    if (!Get.isRegistered<SupplierController>()) {
      Get.put(SupplierController(), permanent: true);
    }
    return Get.find<SupplierController>();
  }

  /// Empty is fine; otherwise it must look like an email address.
  String? emailValidator(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text) ? null : 'validation_email_invalid'.tr;
  }

  @override
  void fillFrom(SupplierData item) {
    contactPersonController.text = item.contactPerson ?? '';
    phoneController.text = item.phone ?? '';
    emailController.text = item.email ?? '';
    addressController.text = item.address ?? '';
  }

  @override
  Map<String, dynamic> extraBody() => {
        'contactPerson': textOrNull(contactPersonController),
        'phone': textOrNull(phoneController),
        'email': textOrNull(emailController),
        'address': textOrNull(addressController),
      };

  @override
  void onClose() {
    contactPersonController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.onClose();
  }
}
