import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/master_form_controller.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_text_field.dart';

/// Code field at the top of a master-data Add/Edit form. Chosen once when
/// adding (shown upper-case on the server); read-only when editing.
class MasterCodeField extends StatelessWidget {
  const MasterCodeField({super.key, required this.controller});

  final MasterFormController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'field_code'.tr,
      controller: controller.codeController,
      hintText: 'hint_code_example'.tr,
      helperText: controller.isEditing ? 'hint_code_locked'.tr : null,
      enabled: !controller.isEditing,
      validator: controller.isEditing ? null : controller.codeValidator,
    );
  }
}

/// Bottom of a master-data Add/Edit form: the error banner and the save button.
class MasterFormFooter extends StatelessWidget {
  const MasterFormFooter({super.key, required this.controller, required this.addLabel});

  final MasterFormController controller;

  /// Button text when adding; editing always says "Save changes".
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          final error = controller.errorMessage.value;
          if (error == null) return const SizedBox.shrink();
          return Container(
            width: double.infinity,
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
            label: controller.isEditing ? 'action_save_changes'.tr : addLabel,
            onPressed: controller.save,
            isLoading: controller.isSaving.value,
          ),
        ),
      ],
    );
  }
}

/// Shown instead of an empty list when loading failed.
class MasterListError extends StatelessWidget {
  const MasterListError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          AppButton(label: 'action_retry'.tr, onPressed: onRetry, variant: AppButtonVariant.secondary, expand: false),
        ],
      ),
    );
  }
}
