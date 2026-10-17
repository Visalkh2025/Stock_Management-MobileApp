import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/login_controller.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_logo_icon.dart';
import 'package:stock_management/View/Components/app_text_field.dart';
import 'package:stock_management/View/Components/auth_background.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 35),
                _logoHeader,
                const SizedBox(height: 27.5),
                _loginCard,
                const SizedBox(height: 22),
                _contactAdminNote,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget get _logoHeader {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const AppLogoIcon(size: 28),
        ),
        const SizedBox(height: 12),
        const Text(
          'StockFlow',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFFF3F2FA),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget get _loginCard {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'welcome_back'.tr,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              'sign_in_subtitle'.tr,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted),
            ),
            const SizedBox(height: 22),
            AppTextField(
              label: 'field_user_id'.tr,
              controller: controller.userIdController,
              hintText: 'STF-2045',
              validator: controller.validateUserId,
            ),
            const SizedBox(height: 14),
            Obx(
              () => AppTextField(
                label: 'field_password'.tr,
                controller: controller.passwordController,
                hintText: 'hint_password'.tr,
                obscureText: controller.obscurePassword.value,
                validator: controller.validatePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscurePassword.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 19,
                    color: AppColors.muted,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: 'action_forgot_password'.tr,
                onPressed: controller.goToForgotPassword,
                variant: AppButtonVariant.text,
                expand: false,
              ),
            ),
            const SizedBox(height: 2),
            Obx(
              () => AppButton(
                label: 'action_sign_in'.tr,
                isLoading: controller.isLoading.value,
                onPressed: controller.signIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _contactAdminNote {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF9C99AD)),
        children: [
          TextSpan(text: 'no_account_prefix'.tr),
          TextSpan(text: 'action_contact_admin'.tr, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brand100)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
