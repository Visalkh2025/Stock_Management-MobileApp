import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/price_input.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/edit_product_controller.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_picker_field.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/app_text_field.dart';
import 'package:stock_management/View/Components/variant_photo_box.dart';

/// Edit Product — the same fields as Add Product, filled with the current
/// values. See [EditProductController].
class EditProductScreen extends GetView<EditProductController> {
  const EditProductScreen({super.key});

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
                    _sectionLabel('section_product_info'.tr),
                    const SizedBox(height: 10),
                    _infoCard,
                    if (controller.hasVariants) ...[
                      const SizedBox(height: 18),
                      _sectionLabel('section_variants'.tr),
                      const SizedBox(height: 10),
                      for (final draft in controller.variantDrafts) ...[
                        _variantCard(draft),
                        const SizedBox(height: 12),
                      ],
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'edit_product_stock_note'.tr,
                      style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    Obx(() {
                      final error = controller.errorMessage.value;
                      if (error == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withAlpha(24),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.danger.withAlpha(90)),
                        ),
                        child: Text(error, style: TextStyle(fontSize: 12.5, color: AppColors.danger)),
                      );
                    }),
                    Obx(
                      () => AppButton(
                        label: 'action_save'.tr,
                        onPressed: controller.save,
                        isLoading: controller.isSaving.value,
                      ),
                    ),
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
            Expanded(
              child: Text(
                'edit_product_title'.tr,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
                overflow: TextOverflow.ellipsis,
              ),
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

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      );

  Widget get _infoCard {
    const money = TextInputType.numberWithOptions(decimal: true);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        children: [
          AppTextField(
            label: 'field_product_name'.tr,
            controller: controller.nameController,
            validator: controller.requiredValidator,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'field_sku'.tr,
                  controller: controller.skuController,
                  validator: controller.requiredValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(label: 'field_barcode'.tr, controller: controller.barcodeController)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Obx(
                  () => AppPickerField(
                    label: 'field_category'.tr,
                    value: controller.selectedCategory.value,
                    options: controller.categories.toList(),
                    isLoading: controller.isLoadingOptions.value,
                    required: true,
                    onChanged: (v) => controller.selectedCategory.value = v,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => AppPickerField(
                    label: 'field_brand'.tr,
                    value: controller.selectedBrand.value,
                    options: controller.brands.toList(),
                    isLoading: controller.isLoadingOptions.value,
                    hintText: 'hint_optional'.tr,
                    onChanged: (v) => controller.selectedBrand.value = v,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Obx(
                  () => AppPickerField(
                    label: 'field_supplier'.tr,
                    value: controller.selectedSupplier.value,
                    options: controller.suppliers.toList(),
                    isLoading: controller.isLoadingOptions.value,
                    hintText: 'hint_optional'.tr,
                    onChanged: (v) => controller.selectedSupplier.value = v,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'field_unit'.tr,
                  controller: controller.unitController,
                  validator: controller.requiredValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_description'.tr,
            controller: controller.descriptionController,
            hintText: 'hint_description_notes_optional'.tr,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'field_min_stock'.tr,
                  controller: controller.minStockController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'field_max_stock'.tr,
                  controller: controller.maxStockController,
                  hintText: 'hint_optional'.tr,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          if (!controller.hasVariants) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'field_cost_price'.tr,
                    validator: validatePrice,
                    inputFormatters: priceInputFormatters,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: controller.costPriceController,
                    prefixText: '\$ ',
                    keyboardType: money,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'field_sale_price'.tr,
                    validator: validatePrice,
                    inputFormatters: priceInputFormatters,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: controller.sellingPriceController,
                    prefixText: '\$ ',
                    keyboardType: money,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _variantCard(EditVariantDraft draft) {
    const money = TextInputType.numberWithOptions(decimal: true);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.code,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Obx(
                () => VariantPhotoBox(
                  file: draft.newImage.value,
                  url: draft.imageUrl,
                  onPick: (source) => controller.pickVariantImage(draft, source),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'variant_photo_hint'.tr,
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_variant_name'.tr,
            controller: draft.nameController,
            validator: controller.requiredValidator,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'field_sku'.tr,
                  controller: draft.skuController,
                  validator: controller.requiredValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(label: 'field_barcode'.tr, controller: draft.barcodeController)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'field_cost_price'.tr,
                  validator: validatePrice,
                  inputFormatters: priceInputFormatters,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: draft.costController,
                  prefixText: '\$ ',
                  keyboardType: money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'field_sale_price'.tr,
                  validator: validatePrice,
                  inputFormatters: priceInputFormatters,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: draft.sellController,
                  prefixText: '\$ ',
                  keyboardType: money,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
