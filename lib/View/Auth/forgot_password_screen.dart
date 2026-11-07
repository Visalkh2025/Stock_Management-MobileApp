import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/forgot_password_controller.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_text_field.dart';

/// Forgot password: Staff ID → email code → new password.
/// See [ForgotPasswordController].
class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

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
                child: Obx(() {
                  switch (controller.step.value) {
                    case 0:
                      return _staffStep();
                    case 1:
                      return _otpStep();
                    default:
                      return _passwordStep();
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _backButton {
    return Material(
      color: AppColors.brand50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: controller.back,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.arrow_back, size: 17, color: AppColors.ink),
        ),
      ),
    );
  }

  Widget _header(IconData icon, String title, String subtitle) {
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
          child: Icon(icon, size: 24, color: AppColors.brand700),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted, height: 1.5),
        ),
      ],
    );
  }

  // ---- Step 0: Staff ID ----
  Widget _staffStep() {
    return Form(
      key: controller.staffFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.lock_reset, 'forgot_title'.tr, 'forgot_staff_subtitle'.tr),
          const SizedBox(height: 22),
          AppTextField(
            label: 'field_user_id'.tr,
            controller: controller.staffIdController,
            validator: controller.validateStaffId,
            fillColor: AppColors.muted.withAlpha(25),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'forgot_send_code'.tr,
            isLoading: controller.isLoading.value,
            onPressed: controller.sendCode,
          ),
        ],
      ),
    );
  }

  // ---- Step 1: six-digit code ----
  Widget _otpStep() {
    return Form(
      key: controller.otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            Icons.mark_email_read_outlined,
            'forgot_otp_title'.tr,
            'forgot_otp_subtitle'.trParams({'staffId': controller.staffId}),
          ),
          const SizedBox(height: 22),
          AppTextField(
            label: 'field_otp'.tr,
            controller: controller.otpController,
            keyboardType: TextInputType.number,
            hintText: '000000',
            validator: controller.validateOtp,
            fillColor: AppColors.muted.withAlpha(25),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'forgot_verify'.tr,
            isLoading: controller.isLoading.value,
            onPressed: controller.verifyOtp,
          ),
          const SizedBox(height: 8),
          Center(
            child: AppButton(
              variant: AppButtonVariant.text,
              expand: false,
              label: controller.resendIn.value > 0
                  ? 'forgot_resend_in'.trParams({'seconds': '${controller.resendIn.value}'})
                  : 'forgot_resend'.tr,
              onPressed: controller.resendIn.value > 0 ? null : controller.resend,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Step 2: new password ----
  Widget _passwordStep() {
    return Form(
      key: controller.passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.lock_outline, 'forgot_new_password_title'.tr, 'forgot_new_password_subtitle'.tr),
          const SizedBox(height: 22),
          AppTextField(
            label: 'field_new_password'.tr,
            controller: controller.newPasswordController,
            obscureText: controller.obscureNew.value,
            helperText: 'validation_password_min_8_helper'.tr,
            validator: controller.validateNew,
            fillColor: AppColors.muted.withAlpha(25),
            suffixIcon: _eye(controller.obscureNew),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_confirm_password'.tr,
            controller: controller.confirmPasswordController,
            obscureText: controller.obscureConfirm.value,
            validator: controller.validateConfirm,
            fillColor: AppColors.muted.withAlpha(25),
            suffixIcon: _eye(controller.obscureConfirm),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'action_reset_password'.tr,
            isLoading: controller.isLoading.value,
            onPressed: controller.resetPassword,
          ),
        ],
      ),
    );
  }

  Widget _eye(RxBool obscure) {
    return IconButton(
      icon: Icon(
        obscure.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 19,
        color: AppColors.muted,
      ),
      onPressed: () => obscure.value = !obscure.value,
    );
  }
}
