import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/stock_form_controller.dart';
import 'package:stock_management/Controller/stock_line.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_picker_field.dart';
import 'package:stock_management/View/Components/app_text_field.dart';
import 'package:stock_management/View/Components/stock_form_parts.dart';
import 'package:stock_management/View/Components/stock_product_picker.dart';

/// The products of a stock-movement form: one card per [StockLine] and an
/// "Add another product" button. Each card has its own product, variant and
/// quantity, and shows its own Current -> After (or On hand -> Moving) preview.
class StockLinesSection extends StatelessWidget {
  const StockLinesSection({super.key, required this.controller, this.lineExtra});

  final StockFormController controller;

  /// Optional widget at the top of each card (Adjust: the Increase/Decrease toggle).
  final Widget Function(StockLine line)? lineExtra;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final lines = controller.lines.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            _LineCard(
              key: ValueKey(lines[i].id),
              controller: controller,
              line: lines[i],
              index: i,
              removable: lines.length > 1,
              extra: lineExtra,
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
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    super.key,
    required this.controller,
    required this.line,
    required this.index,
    required this.removable,
    required this.extra,
  });

  final StockFormController controller;
  final StockLine line;
  final int index;
  final bool removable;
  final Widget Function(StockLine line)? extra;

  /// The warehouse picker of this line (nothing for Transfer, which has one
  /// route for the whole request).
  List<Widget> _warehouseField() {
    if (!controller.warehousePerLine) return const [];
    return [
      Obx(
        () => AppPickerField(
          label: controller.warehouseLabel,
          value: line.warehouse.value,
          options: controller.warehouseOptionsFor(line),
          isLoading: controller.isLoadingWarehouses.value,
          required: true,
          allowClear: false,
          prefixIcon: const Icon(Icons.warehouse_outlined, size: 20, color: AppColors.textTertiary),
          onChanged: (v) => line.warehouse.value = v,
        ),
      ),
      if (!controller.productFirst) const SizedBox(height: 14),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (removable)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'label_product_n'.trParams({'n': '${index + 1}'}).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => controller.removeLine(line),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          if (extra != null) ...[extra!(line), const SizedBox(height: 14)],
          if (!controller.productFirst) ..._warehouseField(),
          StockProductPicker(
            line: line,
            catalog: controller.catalog,
            warehouse: () => controller.warehouseOf(line),
            onlyInStock: () => controller.requiresStock(line),
            onSelected: (item) => controller.pickProduct(line, item),
          ),
          StockFormVariantPicker(line: line, onChanged: () => controller.syncWarehouse(line)),
          if (controller.productFirst) ...[
            const SizedBox(height: 14),
            ..._warehouseField(),
            _StoredIn(controller: controller, line: line),
          ],
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_quantity'.tr,
            controller: line.quantityController,
            hintText: 'hint_quantity_example'.tr,
            keyboardType: TextInputType.number,
            validator: controller.quantityValidator,
          ),
          Obx(() {
            // Re-read whatever the preview depends on so it stays live.
            line.product.value;
            line.variant.value;
            line.enteredQty.value;
            line.warehouse.value;
            controller.warehouseOf(line);
            line.increase.value;
            final impact = controller.impactOf(line);
            if (impact == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _ImpactView(impact: impact),
            );
          }),
        ],
      ),
    );
  }
}

class _ImpactView extends StatelessWidget {
  const _ImpactView({required this.impact});

  final LineImpact impact;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (impact.tone) {
      ImpactTone.positive => (AppColors.success, AppColors.successBg),
      ImpactTone.danger => (AppColors.danger, AppColors.dangerBg),
      ImpactTone.neutral => (AppColors.ink, AppColors.pageBg),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _stat(impact.leftLabel, impact.leftValue, AppColors.ink, AppColors.pageBg)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textTertiary),
            ),
            Expanded(child: _stat(impact.rightLabel, impact.rightValue, color, bg)),
          ],
        ),
        if (impact.warning != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    impact.warning!,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _stat(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

/// "Currently in: Warehouse A · 20, Warehouse B · 5" under the warehouse
/// picker — where the chosen product is stored now. Tap one to pick it.
class _StoredIn extends StatelessWidget {
  const _StoredIn({required this.controller, required this.line});

  final StockFormController controller;
  final StockLine line;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (line.product.value == null) return const SizedBox.shrink();
      line.variant.value;
      final options = controller.warehouseOptionsFor(line);
      final stored = [
        for (final e in controller.storedWarehouses(line))
          if (options.contains(e.$1)) e,
      ];
      final selected = line.warehouse.value;
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: stored.isEmpty
            ? Text(
                'hint_not_stored_yet'.tr,
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'label_stored_in'.tr,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (w, qty) in stored)
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => line.warehouse.value = w,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected == w ? AppColors.brand50 : AppColors.pageBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: selected == w ? AppColors.brand600 : AppColors.border),
                            ),
                            child: Text(
                              '${w.name} · $qty',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected == w ? AppColors.brand700 : AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      );
    });
  }
}
