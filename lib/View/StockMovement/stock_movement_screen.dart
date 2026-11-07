import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/stock_movement_controller.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/stock_form_parts.dart';
import 'package:stock_management/View/Components/stock_lines_section.dart';
import 'package:stock_management/View/Components/app_text_field.dart';

/// Reached from Home's header "Stock In"/"Stock Out" buttons — one screen
class StockMovementScreen extends GetView<StockMovementController> {
  const StockMovementScreen({super.key});

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
                    _sectionLabel(controller.direction.detailsCardTitle),
                    const SizedBox(height: 10),
                    StockLinesSection(controller: controller),
                    const SizedBox(height: 18),
                    _sectionLabel('field_reason'.tr),
                    const SizedBox(height: 10),
                    _warehouseCard,
                    const SizedBox(height: 18),
                    StockFormFooter(controller: controller, saveLabel: controller.direction.ctaLabel),
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
              controller.direction.displayTitle,
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
        hintText: controller.direction.reasonHint,
      ),
    );
  }
}
