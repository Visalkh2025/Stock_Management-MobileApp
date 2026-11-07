import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/new_request_controller.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/app_text_field.dart';

/// The FAB on the Requests screen (and Purchase Orders' "+Add") lands here.
class NewRequestScreen extends GetView<NewRequestController> {
  const NewRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: SafeArea(
              top: false,
              child: Form(
                key: controller.formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    _productShortcut,
                    const SizedBox(height: 18),
                    _sectionLabel('section_details'.tr),
                    const SizedBox(height: 10),
                    _detailsCard,
                    const SizedBox(height: 18),
                    _sectionLabel('purchase_order_details_section'.tr),
                    const SizedBox(height: 10),
                    _orderDetailsCard,
                    const SizedBox(height: 24),
                    AppButton(label: 'submit_request'.tr, onPressed: controller.save),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
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
              'new_purchase_order_title'.tr,
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

  Widget get _productShortcut {
    return InkWell(
      onTap: () => Get.toNamed(Routes.addProduct),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 15, color: AppColors.brand700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'product_shortcut_hint'.tr,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brand700),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.brand700),
          ],
        ),
      ),
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
          AppTextField(
            label: 'field_product'.tr,
            controller: controller.productController,
            hintText: 'hint_product_example'.tr,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'validation_required'.tr : null,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(label: 'field_sku'.tr, controller: controller.skuController, hintText: 'hint_optional'.tr),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'field_quantity'.tr,
                  controller: controller.quantityController,
                  hintText: 'hint_quantity_example'.tr,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'validation_required'.tr : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget get _orderDetailsCard {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: AppTextField(
        label: 'field_supplier'.tr,
        controller: controller.supplierController,
        hintText: 'hint_supplier_example'.tr,
      ),
    );
  }
}
