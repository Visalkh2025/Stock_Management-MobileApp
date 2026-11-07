import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/auth_service.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';

/// More > Settings > Change password — any signed-in user changes their own
/// password (`POST /auth/change-password`).
class ChangePasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  final obscureCurrent = true.obs;
  final obscureNew = true.obs;
  final obscureConfirm = true.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  final AuthService _authService = AuthService();

  String? validateCurrent(String? v) =>
      (v == null || v.isEmpty) ? 'validation_current_password_required'.tr : null;

  String? validateNew(String? v) {
    if (v == null || v.isEmpty) return 'validation_new_password_required'.tr;
    if (v.length < 8) return 'validation_password_min_8_helper'.tr;
    if (v == currentController.text) return 'validation_password_same_as_current'.tr;
    return null;
  }

  String? validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'validation_confirm_password_required'.tr;
    if (v != newController.text) return 'validation_passwords_do_not_match'.tr;
    return null;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    errorMessage.value = null;
    isLoading.value = true;
    try {
      await _authService.changePassword(
        currentPassword: currentController.text,
        newPassword: newController.text,
      );
      Get.back();
      AppSnackbar.success(
        'change_password_success_title'.tr,
        'change_password_success'.tr,
      );
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}
