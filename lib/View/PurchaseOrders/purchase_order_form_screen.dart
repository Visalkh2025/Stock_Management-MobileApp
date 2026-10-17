import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/purchase_order_form_controller.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_picker_field.dart';
import 'package:stock_management/View/Components/app_text_field.dart';
import 'package:stock_management/View/Components/stock_form_parts.dart';
import 'package:stock_management/View/Components/stock_product_picker.dart';
import 'package:stock_management/View/PurchaseOrders/po_import_sheet.dart';
import 'package:stock_management/View/PurchaseOrders/po_parts.dart';

/// New / Edit purchase order: supplier, receiving warehouse and the products
/// (quantity + price each). Save as a draft, or submit for approval.
class PurchaseOrderFormScreen extends GetView<PurchaseOrderFormController> {
  const PurchaseOrderFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PoHeader(title: controller.isEditing ? 'po_edit_title'.tr : 'po_new_title'.tr),
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
                return Form(
                  key: controller.formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      PoSectionLabel('po_section_details'.tr),
                      const SizedBox(height: 10),
                      _detailsCard,
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(child: PoSectionLabel('po_section_products'.tr)),
                          _importButton(context),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _lines,
                      const SizedBox(height: 14),
                      _totalCard,
                      const SizedBox(height: 22),
                      _footer,
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _importButton(BuildContext context) {
    return Obx(
      () => TextButton.icon(
        onPressed: controller.isImporting.value ? null : () => _import(context),
        icon: controller.isImporting.value
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.upload_file_rounded, size: 18),
        label: Text('po_import_excel'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  /// Pick a file -> the server checks it -> show the result -> add the good rows.
  Future<void> _import(BuildContext context) async {
    final preview = await controller.pickAndPreview();
    if (preview == null || !context.mounted) return;
    final add = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => PoImportSheet(preview: preview),
    );
    if (add != true) return;
    final result = controller.applyImport(preview);
    final skipped = result.skipped == 0 ? '' : ' • ${'po_import_skipped'.trParams({'count': '${result.skipped}'})}';
    Get.snackbar(
      'po_import_excel'.tr,
      '${'po_import_done'.trParams({'count': '${result.added}'})}$skipped',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Widget get _detailsCard {
    return PoCard(
      child: Column(
        children: [
          AppPickerField(
            label: 'field_supplier'.tr,
            value: controller.supplier.value,
            options: controller.suppliers.toList(),
            required: true,
            allowClear: false,
            prefixIcon: const Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.textTertiary),
            onChanged: (v) => controller.supplier.value = v,
          ),
          const SizedBox(height: 14),
          AppPickerField(
            label: 'po_field_receiving_warehouse'.tr,
            value: controller.warehouse.value,
            options: controller.warehouses.toList(),
            required: true,
            allowClear: false,
            prefixIcon: const Icon(Icons.warehouse_outlined, size: 20, color: AppColors.textTertiary),
            onChanged: (v) => controller.warehouse.value = v,
          ),
          if (controller.needsApprover) ...[
            const SizedBox(height: 14),
            AppPickerField(
              label: 'po_field_approver'.tr,
              hintText: 'po_hint_approver'.tr,
              value: controller.approver.value,
              options: controller.approvers.toList(),
              allowClear: false,
              prefixIcon: const Icon(Icons.how_to_reg_outlined, size: 20, color: AppColors.textTertiary),
              onChanged: (v) => controller.approver.value = v,
            ),
          ],
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_note'.tr,
            controller: controller.noteController,
            hintText: 'hint_optional'.tr,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget get _lines {
    return Obx(() {
      final lines = controller.lines.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            _LineCard(
              key: ValueKey(lines[i].line.id),
              controller: controller,
              line: lines[i],
              index: i,
              removable: lines.length > 1,
            ),
            const SizedBox(height: 12),
          ],
          AppButton(
            label: 'action_add_another_product'.tr,
            icon: Icons.add_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: controller.addLine,
          ),
        ],
      );
    });
  }

  Widget get _totalCard {
    return PoCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              'po_total'.tr,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
          ),
          Obx(
            () => Text(
              formatMoney(controller.total),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.brand700),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _footer {
    return Obx(() {
      final error = controller.errorMessage.value;
      final saving = controller.isSaving.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) PoErrorBanner(error),
          AppButton(
            label: (controller.needsApprover ? 'po_action_submit' : 'po_action_create_approved').tr,
            isLoading: saving,
            onPressed: saving ? null : () => controller.save(submit: true),
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'po_action_save_draft'.tr,
            variant: AppButtonVariant.secondary,
            onPressed: saving ? null : () => controller.save(submit: false),
          ),
        ],
      );
    });
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    super.key,
    required this.controller,
    required this.line,
    required this.index,
    required this.removable,
  });

  final PurchaseOrderFormController controller;
  final PoLine line;
  final int index;
  final bool removable;

  /// Existing product / New product switch.
  Widget get _kindToggle {
    return Obx(
      () => Row(
        children: [
          ChoiceChip(
            label: Text('po_kind_existing'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            selected: !line.isNew.value,
            onSelected: (_) => line.setNew(false),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('po_kind_new'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            selected: line.isNew.value,
            onSelected: (_) => line.setNew(true),
          ),
        ],
      ),
    );
  }

  Widget get _existingProductFields {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StockProductPicker(
          line: line.line,
          catalog: controller.catalog,
          warehouse: () => null,
          onlyInStock: () => false,
          onSelected: line.selectProduct,
        ),
        StockFormVariantPicker(line: line.line, onChanged: () => line.selectVariant(line.line.variant.value)),
      ],
    );
  }

  /// A product that is not in the catalogue yet: name + category (+ unit and
  /// an optional SKU). It is created when the goods are received.
  Widget get _newProductFields {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'po_field_new_name'.tr,
          controller: line.nameController,
          hintText: 'po_hint_new_name'.tr,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'validation_required'.tr : null,
        ),
        const SizedBox(height: 14),
        AppPickerField(
          label: 'field_category'.tr,
          value: line.category.value,
          options: controller.categories.toList(),
          required: true,
          allowClear: false,
          prefixIcon: const Icon(Icons.category_outlined, size: 20, color: AppColors.textTertiary),
          onChanged: (v) => line.category.value = v,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(label: 'field_unit'.tr, controller: line.unitController),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'po_field_new_sku'.tr,
                controller: line.skuController,
                hintText: 'po_hint_new_sku'.tr,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('po_new_product_note'.tr, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'label_product_n'.trParams({'n': '${index + 1}'}).toUpperCase(),
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
                ),
              ),
              if (removable)
                InkWell(
                  onTap: () => controller.removeLine(line),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 18, color: AppColors.textTertiary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _kindToggle,
          const SizedBox(height: 12),
          Obx(() => line.isNew.value ? _newProductFields : _existingProductFields),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'field_quantity'.tr,
                  controller: line.line.quantityController,
                  keyboardType: TextInputType.number,
                  validator: controller.quantityValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'po_field_unit_price'.tr,
                  controller: line.priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixText: '\$ ',
                  validator: controller.priceValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Obx(
              () => Text(
                '${'po_line_total'.tr}: ${formatMoney(line.total)}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
