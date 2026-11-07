import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/new_password_controller.dart';
import 'package:stock_management/Controller/profile_controller.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/auth_service.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';

/// Handles form state and sign-in for [LoginScreen].
class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final userIdController = TextEditingController();
  final passwordController = TextEditingController();

  final obscurePassword = true.obs;
  final isLoading = false.obs;

  final AuthService _authService = AuthService();

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  String? validateUserId(String? value) {
    if (value == null || value.trim().isEmpty) return 'validation_user_id_required'.tr;
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'validation_password_required'.tr;
    if (value.length < 6) return 'validation_password_min_length'.tr;
    return null;
  }

  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    isLoading.value = true;
    try {
      final result = await _authService.login(
        staffId: userIdController.text.trim(),
        password: passwordController.text,
      );

      // `/auth/login` already returns the full profile (see UsersService.getMe on the backend) — hand it straight to ProfileController so the More/Home/Profile screens show the real signed-in user with no extra request.
      if (!Get.isRegistered<ProfileController>()) {
        Get.put(ProfileController(), permanent: true);
      }
      Get.find<ProfileController>().loadFromAuthUser(result.user);
      
      if (result.mustChangePassword) {
        // NewPasswordController is a permanent singleton (see AuthBinding), so its onInit() already ran once, long before this password existed — Get.arguments would never reach it.
        if (!Get.isRegistered<NewPasswordController>()) {
          Get.put(NewPasswordController(), permanent: true);
        }
        Get.find<NewPasswordController>().setCurrentPassword(passwordController.text);
        Get.offAllNamed(Routes.newPassword);
      } else {
        Get.offAllNamed(Routes.home);
      }
    } on ApiException catch (e) {
      AppSnackbar.error(
        'login_failed_title'.tr,
        e.message,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void goToForgotPassword() {
    Get.toNamed(Routes.forgotPassword, arguments: userIdController.text.trim());
  }

  @override
  void onClose() {
    userIdController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
