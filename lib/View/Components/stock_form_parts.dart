import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/stock_form_controller.dart';
import 'package:stock_management/Controller/stock_line.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_picker_field.dart';
import 'package:stock_management/View/Components/approval_chain_card.dart';

/// Variant picker of a stock-movement line. Renders nothing until the chosen
/// product has variants.
class StockFormVariantPicker extends StatelessWidget {
  const StockFormVariantPicker({super.key, required this.line, this.onChanged});

  final StockLine line;

  /// Called after the variant changes.
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!line.needsVariant) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: AppPickerField(
          label: 'field_variant'.tr,
          value: line.variant.value,
          options: line.variantOptions,
          required: true,
          allowClear: false,
          prefixIcon: const Icon(Icons.style_outlined, size: 20, color: AppColors.textTertiary),
          onChanged: (v) {
            line.variant.value = v;
            onChanged?.call();
          },
        ),
      );
    });
  }
}

/// Bottom of a stock-movement form: the approval chain (only for people who
/// must send a request), the error banner and the submit button.
class StockFormFooter extends StatelessWidget {
  const StockFormFooter({super.key, required this.controller, required this.saveLabel});

  final StockFormController controller;

  /// Button text for a direct save; people who must send a request get
  /// "Submit request" instead.
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.needsApproval) ...[
          Text(
            'section_approvers'.tr.toUpperCase(),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          ApprovalChainCard(chain: controller.chain, helpText: 'hint_approver_help_stock'.tr),
          const SizedBox(height: 18),
        ],
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
            label: controller.needsApproval ? 'action_submit_request'.tr : saveLabel,
            onPressed: controller.save,
            isLoading: controller.isSaving.value,
          ),
        ),
      ],
    );
  }
}
