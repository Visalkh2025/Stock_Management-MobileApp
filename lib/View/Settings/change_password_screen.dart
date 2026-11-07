import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/change_password_controller.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/app_text_field.dart';
import 'package:stock_management/View/PurchaseOrders/po_parts.dart';

/// Change my own password. See [ChangePasswordController].
class ChangePasswordScreen extends GetView<ChangePasswordController> {
  const ChangePasswordScreen({super.key});

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
                    Text(
                      'change_password_subtitle'.tr,
                      style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    PoCard(
                      child: Column(
                        children: [
                          _field(
                            label: 'field_current_password'.tr,
                            textController: controller.currentController,
                            obscure: controller.obscureCurrent,
                            validator: controller.validateCurrent,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            label: 'field_new_password'.tr,
                            textController: controller.newController,
                            obscure: controller.obscureNew,
                            validator: controller.validateNew,
                            helper: 'validation_password_min_8_helper'.tr,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            label: 'field_confirm_password'.tr,
                            textController: controller.confirmController,
                            obscure: controller.obscureConfirm,
                            validator: controller.validateConfirm,
                          ),
                        ],
                      ),
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
                        isLoading: controller.isLoading.value,
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

  Widget _field({
    required String label,
    required TextEditingController textController,
    required RxBool obscure,
    required String? Function(String?) validator,
    String? helper,
  }) {
    return Obx(
      () => AppTextField(
        label: label,
        controller: textController,
        obscureText: obscure.value,
        helperText: helper,
        validator: validator,
        suffixIcon: IconButton(
          icon: Icon(
            obscure.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 19,
            color: AppColors.muted,
          ),
          onPressed: () => obscure.value = !obscure.value,
        ),
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
                'change_password_title'.tr,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
