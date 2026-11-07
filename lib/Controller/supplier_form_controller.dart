import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/supplier_controller.dart';
import 'package:stock_management/Controller/master_form_controller.dart';
import 'package:stock_management/Model/lookup_models.dart';
import 'package:stock_management/Model/master_data_models.dart';

/// Add/Edit form behind Manage > Suppliers — see [MasterFormController].
class SupplierFormController extends MasterFormController<SupplierData> {
  final contactPersonController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final platformLinkController = TextEditingController();
  final countryController = TextEditingController();

  /// How the supplier is reached online. The code is what the server stores.
  static const _platformNames = {
    'TELEGRAM': 'Telegram',
    'WHATSAPP': 'WhatsApp',
    'FACEBOOK': 'Facebook',
    'WECHAT': 'WeChat',
    'LINE': 'Line',
    'INSTAGRAM': 'Instagram',
    'WEBSITE': 'Website',
  };

  List<LookupOption> get platforms => [
        for (final e in _platformNames.entries) LookupOption(id: e.key, code: e.key, name: e.value),
        LookupOption(id: 'OTHER', code: 'OTHER', name: 'platform_other'.tr),
      ];

  final platform = Rxn<LookupOption>();

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
    platformLinkController.text = item.platformLink ?? '';
    countryController.text = item.country ?? '';
    for (final option in platforms) {
      if (option.code == item.platform) platform.value = option;
    }
  }

  @override
  Map<String, dynamic> extraBody() => {
        'contactPerson': textOrNull(contactPersonController),
        'phone': textOrNull(phoneController),
        'email': textOrNull(emailController),
        'address': textOrNull(addressController),
        'platform': platform.value?.code,
        // A link without a platform has no meaning, so it is dropped.
        'platformLink': platform.value == null ? null : textOrNull(platformLinkController),
        'country': textOrNull(countryController),
      };

  @override
  void onClose() {
    contactPersonController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    platformLinkController.dispose();
    countryController.dispose();
    super.onClose();
  }
}
