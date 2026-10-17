import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/auth_service.dart';

/// Forces a password change right after sign-in, and doubles as the
/// "set new password" step at the end of the forgot-password flow.
///
/// Registered as a *permanent* singleton by [AuthBinding] (shared with
/// [LoginController] so both survive the Login <-> New Password
/// `Get.offAllNamed` jump without their TextEditingControllers getting
/// disposed mid-transition). Because it's permanent, `onInit()` only ever
/// runs once — the very first time either the Login or New Password page
/// is built, typically before any password has been typed. Reading
/// `Get.arguments` there would capture nothing and never update again.
/// So instead of onInit/Get.arguments, [LoginController] calls
/// [setCurrentPassword] directly on this already-alive instance right
/// before navigating here — the same pattern it uses to hand data to the
/// permanent `ProfileController`.
class NewPasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final obscureNewPassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isLoading = false.obs;

  final AuthService _authService = AuthService();

  /// The password the user just signed in with (their temporary password).
  /// Set by [LoginController] via [setCurrentPassword] right before it
  /// navigates here, since `POST /auth/change-password` needs it
  /// alongside the new password.
  String? _currentPassword;

  void setCurrentPassword(String password) {
    _currentPassword = password;
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.value = !obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'validation_new_password_required'.tr;
    if (value.length < 8) return 'validation_password_min_8_helper'.tr;
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'validation_confirm_password_required'.tr;
    if (value != newPasswordController.text) return 'validation_passwords_do_not_match'.tr;
    return null;
  }

  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final currentPassword = _currentPassword;
    if (currentPassword == null || currentPassword.isEmpty) {
      // Shouldn't happen in the normal flow — the temporary password is
      // always passed in from LoginController. If it's missing (e.g. this
      // screen was reached some other way), there's nothing safe to submit.
      Get.offAllNamed(Routes.login);
      return;
    }

    isLoading.value = true;
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPasswordController.text,
      );
      Get.offAllNamed(Routes.home);
    } on ApiException catch (e) {
      Get.snackbar(
        'change_password_failed_title'.tr,
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
