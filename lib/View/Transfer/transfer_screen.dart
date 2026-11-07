import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/transfer_controller.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/app_picker_field.dart';
import 'package:stock_management/View/Components/stock_form_parts.dart';
import 'package:stock_management/View/Components/stock_lines_section.dart';

/// Reached from Home's "Transfer" quick action (see Routes.transfer, TransferBinding).
class TransferScreen extends GetView<TransferController> {
  const TransferScreen({super.key});

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
                    _sectionLabel('section_route'.tr),
                    const SizedBox(height: 10),
                    _routeCard,
                    const SizedBox(height: 18),
                    _sectionLabel('section_transfer_details'.tr),
                    const SizedBox(height: 10),
                    StockLinesSection(controller: controller),
                    const SizedBox(height: 18),
                    StockFormFooter(controller: controller, saveLabel: 'action_confirm_transfer'.tr),
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
              'qa_transfer'.tr,
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

  Widget get _routeCard {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Obx(
              () => AppPickerField(
                label: 'field_from_warehouse'.tr,
                value: controller.warehouse.value,
                options: controller.warehouses,
                isLoading: controller.isLoadingWarehouses.value,
                required: true,
                allowClear: false,
                onChanged: controller.selectSource,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(top: 22),
            child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => AppPickerField(
                label: 'field_to_warehouse'.tr,
                value: controller.toWarehouse.value,
                options: controller.destinationOptions,
                isLoading: controller.isLoadingWarehouses.value,
                required: true,
                allowClear: false,
                onChanged: (v) => controller.toWarehouse.value = v,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
