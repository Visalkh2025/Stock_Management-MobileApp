import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/adjust_controller.dart';
import 'package:stock_management/Controller/stock_line.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/stock_form_parts.dart';
import 'package:stock_management/View/Components/stock_lines_section.dart';
import 'package:stock_management/View/Components/app_text_field.dart';

/// Reached from Home's "Adjust" quick action (see Routes.adjust, AdjustBinding).
class AdjustScreen extends GetView<AdjustController> {
  const AdjustScreen({super.key});

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
                    _sectionLabel('section_adjustment_details'.tr),
                    const SizedBox(height: 10),
                    StockLinesSection(controller: controller, lineExtra: _directionToggle),
                    const SizedBox(height: 18),
                    _sectionLabel('field_reason'.tr),
                    const SizedBox(height: 10),
                    _warehouseCard,
                    const SizedBox(height: 18),
                    StockFormFooter(controller: controller, saveLabel: 'action_confirm_adjustment'.tr),
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
              'qa_adjust'.tr,
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

  Widget _directionToggle(StockLine line) {
    return Obx(
      () => Row(
        children: [
          Expanded(child: _directionChip(line, AdjustmentDirection.increase)),
          const SizedBox(width: 10),
          Expanded(child: _directionChip(line, AdjustmentDirection.decrease)),
        ],
      ),
    );
  }

  Widget _directionChip(StockLine line, AdjustmentDirection value) {
    final isActive = line.increase.value == value.isIncrease;
    final activeColor = value.isIncrease ? AppColors.success : AppColors.danger;
    return Material(
      color: isActive ? activeColor : AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          line.increase.value = value.isIncrease;
          controller.syncWarehouse(line);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isActive ? activeColor : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(value.icon, size: 16, color: isActive ? Colors.white : AppColors.ink),
              const SizedBox(width: 6),
              Text(
                value.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget get _warehouseCard {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: AppTextField(
        label: 'field_reason'.tr,
        controller: controller.reasonController,
        hintText: 'hint_reason_example'.tr,
        validator: controller.requiredText,
      ),
    );
  }
}
