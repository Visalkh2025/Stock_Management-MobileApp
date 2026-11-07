import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/new_password_controller.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_text_field.dart';

import '../../Config/routes/app_routes.dart';

class NewPasswordScreen extends GetView<NewPasswordController> {
  const NewPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _backButton,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header,
                      const SizedBox(height: 22),
                      _newPasswordField,
                      const SizedBox(height: 14),
                      _confirmPasswordField,
                      const SizedBox(height: 18),
                      _submitButton,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget get _header {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: AppColors.brand300.withAlpha(70),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.lock_outline, size: 24, color: AppColors.brand700),
        ),
        Text(
          'create_new_password_title'.tr,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        Text(
          'create_new_password_subtitle'.tr,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted, height: 1.5),
        ),
      ],
    );
  }

    Widget get _backButton {
    return Material(
      color: AppColors.brand50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          Get.offAllNamed(Routes.login);
        },
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.arrow_back, size: 17, color: AppColors.ink),
        ),
      ),
    );
  }

  Widget get _newPasswordField {
    return Obx(
      () => AppTextField(
        label: 'field_new_password'.tr,
        controller: controller.newPasswordController,
        obscureText: controller.obscureNewPassword.value,
        helperText: 'validation_password_min_8_helper'.tr,
        validator: controller.validateNewPassword,
        fillColor: AppColors.muted.withAlpha(25),
        suffixIcon: IconButton(
          icon: Icon(
            controller.obscureNewPassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 19,
            color: AppColors.muted,
          ),
          onPressed: controller.toggleNewPasswordVisibility,
        ),
      ),
    );
  }

  Widget get _confirmPasswordField {
    return Obx(
      () => AppTextField(
        label: 'field_confirm_password'.tr,
        controller: controller.confirmPasswordController,
        obscureText: controller.obscureConfirmPassword.value,
        validator: controller.validateConfirmPassword,
        fillColor: AppColors.muted.withAlpha(25),
        suffixIcon: IconButton(
          icon: Icon(
            controller.obscureConfirmPassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 19,
            color: AppColors.muted,
          ),
          onPressed: controller.toggleConfirmPasswordVisibility,
        ),
      ),
    );
  }

  Widget get _submitButton {
    return Obx(
      () => AppButton(
        label: 'action_reset_password'.tr,
        isLoading: controller.isLoading.value,
        onPressed: controller.resetPassword,
      ),
    );
  }
}
