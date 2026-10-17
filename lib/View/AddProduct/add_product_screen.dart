import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/add_product_controller.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/approval_chain_card.dart';
import 'package:stock_management/View/Components/app_picker_field.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/app_text_field.dart';

/// Add Product form. ADMIN (PRODUCT_CREATE) saves straight to the server;
/// other roles send a request — see [AddProductController].
class AddProductScreen extends GetView<AddProductController> {
  const AddProductScreen({super.key});

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
                    if (controller.canImport) ...[
                      _importCard,
                      const SizedBox(height: 18),
                    ],
                    _sectionLabel('section_product_info'.tr),
                    const SizedBox(height: 10),
                    _productInfoCard,
                    const SizedBox(height: 18),
                    _sectionLabel('section_variants'.tr),
                    const SizedBox(height: 10),
                    _variantsCard,
                    if (controller.needsApproval) ...[
                      const SizedBox(height: 18),
                      _sectionLabel('section_approvers'.tr),
                      const SizedBox(height: 10),
                      ApprovalChainCard(chain: controller.chain, helpText: 'hint_approver_help'.tr),
                    ],
                    const SizedBox(height: 24),
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
                        child: Text(error, style: const TextStyle(fontSize: 12.5, color: AppColors.danger)),
                      );
                    }),
                    Obx(
                      () => AppButton(
                        label: controller.needsApproval ? 'action_submit_request'.tr : 'action_save'.tr,
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
              'add_product_title'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
            ),
          ],
        ),
      ],
    );
  }

  Widget get _importCard {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'import_products_title'.tr,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'import_products_hint'.tr,
            style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: 'import_products_action'.tr,
                  icon: Icons.upload_file_rounded,
                  isLoading: controller.isImporting.value,
                  onPressed: controller.importExcel,
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'import_products_template'.tr,
                  variant: AppButtonVariant.secondary,
                  icon: Icons.download_rounded,
                  onPressed: controller.isImporting.value ? null : controller.downloadTemplate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
    );
  }

  Widget get _imagePicker {
    return Obx(() {
      final image = controller.productImage.value;
      return Center(
        child: GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.pageBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.brand700.withAlpha(30)),
              image: image != null ? DecorationImage(image: FileImage(image), fit: BoxFit.cover) : null,
            ),
            child: image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 22, color: AppColors.textTertiary),
                      SizedBox(height: 6),
                      Text(
                        'add_photo'.tr,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
                      ),
                    ],
                  )
                : Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: controller.removeImage,
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
          ),
        ),
      );
    });
  }

  void _showImageSourceSheet() {
    final context = Get.context;
    if (context == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.brand700),
              title: Text('action_take_photo'.tr),
              onTap: () {
                Get.back();
                controller.pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.brand700),
              title: Text('action_choose_from_gallery'.tr),
              onTap: () {
                Get.back();
                controller.pickImage(ImageSource.gallery);
              },
            ),
            if (controller.productImage.value != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: Text('action_remove_photo'.tr),
                onTap: () {
                  Get.back();
                  controller.removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget get _productInfoCard {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _imagePicker,
          const SizedBox(height: 16),
          AppTextField(
            label: 'field_product_name'.tr,
            controller: controller.nameController,
            hintText: 'hint_product_name_example'.tr,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'validation_required'.tr : null,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'field_sku'.tr,
                  controller: controller.skuController,
                  hintText: 'hint_auto_generated'.tr,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(label: 'field_barcode'.tr, controller: controller.barcodeController, hintText: 'hint_optional'.tr),
              ),
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
              Expanded(child: AppTextField(label: 'field_unit'.tr, controller: controller.unitController, hintText: 'hint_unit_example'.tr)),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_description'.tr,
            controller: controller.descriptionController,
            hintText: 'hint_description_notes_optional'.tr,
            maxLines: 3,
          ),
          Obx(
            () => AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: controller.hasVariants.value
                  ? const SizedBox(width: double.infinity, height: 0)
                  : Column(
                      children: [
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'label_stock_pricing'.tr,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.5),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'field_quantity'.tr,
                                controller: controller.quantityController,
                                hintText: 'hint_zero'.tr,
                                keyboardType: TextInputType.number,
                                validator: controller.quantityValidator,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                label: 'field_min_stock'.tr,
                                controller: controller.minStockController,
                                hintText: 'hint_optional'.tr,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Obx(
                          () => AppPickerField(
                            label: 'field_warehouse'.tr,
                            value: controller.selectedWarehouse.value,
                            options: controller.warehouses.toList(),
                            isLoading: controller.isLoadingOptions.value,
                            required: true,
                            prefixIcon: const Icon(Icons.store_outlined, size: 20, color: AppColors.textTertiary),
                            onChanged: (v) => controller.selectedWarehouse.value = v,
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'field_location'.tr,
                          controller: controller.locationController,
                          hintText: 'hint_location_example'.tr,
                          prefixIcon: const Icon(Icons.place_outlined, size: 20, color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'field_cost_price'.tr,
                                controller: controller.costPriceController,
                                hintText: 'hint_zero_decimal'.tr,
                                prefixText: '\$ ',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                label: 'field_sale_price'.tr,
                                controller: controller.sellingPriceController,
                                hintText: 'hint_zero_decimal'.tr,
                                prefixText: '\$ ',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _totalCostReadout(controller.costPriceController, controller.quantityController, 'total_cost_value'.tr),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalCostReadout(TextEditingController costCtrl, TextEditingController qtyCtrl, String label) {
    return AnimatedBuilder(
      animation: Listenable.merge([costCtrl, qtyCtrl]),
      builder: (context, _) {
        final cost = double.tryParse(costCtrl.text.trim()) ?? 0;
        final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
        final total = cost * qty;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand700)),
              ),
              Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brand700)),
            ],
          ),
        );
      },
    );
  }

  Widget get _variantsCard {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: Text(
                    'has_variants_toggle_label'.tr,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                ),
                Switch(
                  value: controller.hasVariants.value,
                  activeThumbColor: AppColors.brand600,
                  onChanged: controller.toggleHasVariants,
                ),
              ],
            ),
          ),
          Obx(
            () => AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: controller.hasVariants.value
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, thickness: 1, color: AppColors.border),
                        ),
                        for (var i = 0; i < controller.variantDrafts.length; i++) _variantDraftRow(i),
                        if (controller.variantDrafts.isNotEmpty) ...[
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              for (final d in controller.variantDrafts) ...[d.costController, d.quantityController],
                            ]),
                            builder: (context, _) {
                              final total = controller.variantDrafts.fold<double>(0, (sum, d) {
                                final cost = double.tryParse(d.costController.text.trim()) ?? 0;
                                final qty = int.tryParse(d.quantityController.text.trim()) ?? 0;
                                return sum + cost * qty;
                              });
                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'total_cost_value_all_variants'.tr,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand700),
                                      ),
                                    ),
                                    Text(
                                      '\$${total.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brand700),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                        InkWell(
                          onTap: controller.addVariantRow,
                          child: Padding(
                            padding: EdgeInsets.only(top: 4, bottom: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, size: 16, color: AppColors.brand700),
                                SizedBox(width: 6),
                                Text(
                                  'action_add_variant'.tr,
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.brand700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _variantDraftRow(int index) {
    final draft = controller.variantDrafts[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brand700.withAlpha(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'variant_number_label'.trParams({'index': '${index + 1}'}),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              if (controller.variantDrafts.length > 1)
                InkWell(
                  onTap: () => controller.removeVariantRow(index),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AppTextField(
                  label: 'field_name'.tr,
                  controller: draft.nameController,
                  hintText: 'hint_variant_name_example'.tr,
                  fillColor: AppColors.cardBg,
                  validator: controller.requiredText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppTextField(
                  label: 'field_sku'.tr,
                  controller: draft.skuController,
                  hintText: 'hint_auto_generated'.tr,
                  fillColor: AppColors.cardBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_barcode'.tr,
            controller: draft.barcodeController,
            hintText: 'hint_optional'.tr,
            fillColor: AppColors.cardBg,
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'label_stock_pricing'.tr,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.5),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  label: 'field_quantity'.tr,
                  controller: draft.quantityController,
                  hintText: 'hint_zero'.tr,
                  keyboardType: TextInputType.number,
                  fillColor: AppColors.cardBg,
                  validator: controller.quantityValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Obx(
                  () => AppPickerField(
                    label: 'field_warehouse'.tr,
                    value: draft.warehouse.value,
                    options: controller.warehouses.toList(),
                    isLoading: controller.isLoadingOptions.value,
                    required: true,
                    fillColor: AppColors.cardBg,
                    prefixIcon: const Icon(Icons.store_outlined, size: 20, color: AppColors.textTertiary),
                    onChanged: (v) => draft.warehouse.value = v,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_location'.tr,
            controller: draft.locationController,
            hintText: 'hint_location_example'.tr,
            fillColor: AppColors.cardBg,
            prefixIcon: const Icon(Icons.place_outlined, size: 20, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'field_cost_price'.tr,
                  controller: draft.costController,
                  hintText: 'hint_zero_decimal'.tr,
                  prefixText: '\$ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  fillColor: AppColors.cardBg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'field_sale_price'.tr,
                  controller: draft.sellController,
                  hintText: 'hint_zero_decimal'.tr,
                  prefixText: '\$ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  fillColor: AppColors.cardBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: Listenable.merge([draft.costController, draft.quantityController]),
            builder: (context, _) {
              final cost = double.tryParse(draft.costController.text.trim()) ?? 0;
              final qty = int.tryParse(draft.quantityController.text.trim()) ?? 0;
              final total = cost * qty;
              return Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'subtotal_label'.trParams({'total': total.toStringAsFixed(2)}),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
