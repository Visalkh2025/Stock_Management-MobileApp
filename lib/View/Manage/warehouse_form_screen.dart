import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/warehouse_form_controller.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/master_data_parts.dart';
import 'package:stock_management/View/Components/app_text_field.dart';

/// Add/Edit Warehouse — reached from Manage > Warehouses (+Add or a row's
/// edit icon). See [WarehouseFormController].
class WarehouseFormScreen extends GetView<WarehouseFormController> {
  const WarehouseFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header,
          Expanded(
            child: SafeArea(
              top: false,
              child: Form(
                key: controller.formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    _sectionLabel('section_warehouse_details'.tr),
                    const SizedBox(height: 10),
                    _detailsCard,
                    const SizedBox(height: 24),
                    MasterFormFooter(controller: controller, addLabel: 'action_add_warehouse'.tr),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _header {
    return AppScreenHeader(
      children: [
        Row(
          children: [
            Material(
              color: AppScreenHeader.onHeaderSurface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: Get.back,
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppScreenHeader.onHeader),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              controller.isEditing ? 'edit_warehouse_title'.tr : 'add_warehouse_title'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
    );
  }

  Widget get _detailsCard {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          MasterCodeField(controller: controller),
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_name'.tr,
            controller: controller.nameController,
            hintText: 'hint_warehouse_name_example'.tr,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'validation_required'.tr : null,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_address'.tr,
            controller: controller.locationController,
            hintText: 'hint_optional'.tr,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_warehouse_capacity'.tr,
            controller: controller.capacityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hintText: 'hint_warehouse_capacity'.tr,
            helperText: 'helper_warehouse_capacity'.tr,
            validator: controller.capacityValidator,
          ),
        ],
      ),
    );
  }
}
