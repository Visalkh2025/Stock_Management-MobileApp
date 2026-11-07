import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/auth_service.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';

/// Forgot password — three steps on one screen:
/// 0 Staff ID  →  1 six-digit code from the email  →  2 new password.
class ForgotPasswordController extends GetxController {
  static const _resendSeconds = 60;

  final staffIdController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final staffFormKey = GlobalKey<FormState>();
  final otpFormKey = GlobalKey<FormState>();
  final passwordFormKey = GlobalKey<FormState>();

  final step = 0.obs;
  final isLoading = false.obs;
  final resendIn = 0.obs;
  final obscureNew = true.obs;
  final obscureConfirm = true.obs;

  final AuthService _authService = AuthService();
  String _staffId = '';
  String _resetToken = '';
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    // The login screen passes whatever was typed in its Staff ID box.
    final prefill = Get.arguments;
    if (prefill is String && prefill.isNotEmpty) staffIdController.text = prefill;
  }

  String? validateStaffId(String? v) =>
      (v == null || v.trim().isEmpty) ? 'validation_user_id_required'.tr : null;

  String? validateOtp(String? v) =>
      (v == null || !RegExp(r'^\d{6}$').hasMatch(v.trim())) ? 'validation_otp_invalid'.tr : null;

  String? validateNew(String? v) {
    if (v == null || v.isEmpty) return 'validation_new_password_required'.tr;
    if (v.length < 8) return 'validation_password_min_8_helper'.tr;
    return null;
  }

  String? validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'validation_confirm_password_required'.tr;
    if (v != newPasswordController.text) return 'validation_passwords_do_not_match'.tr;
    return null;
  }

  String get staffId => _staffId;

  void _startCooldown() {
    _timer?.cancel();
    resendIn.value = _resendSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendIn.value <= 1) {
        resendIn.value = 0;
        t.cancel();
      } else {
        resendIn.value--;
      }
    });
  }

  void _error(ApiException e) {
    AppSnackbar.error('forgot_failed_title'.tr, e.message);
  }

  Future<void> sendCode() async {
    if (!staffFormKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    try {
      _staffId = staffIdController.text.trim();
      await _authService.forgotPassword(_staffId);
      otpController.clear();
      step.value = 1;
      _startCooldown();
    } on ApiException catch (e) {
      _error(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resend() async {
    if (resendIn.value > 0 || isLoading.value) return;
    isLoading.value = true;
    try {
      await _authService.forgotPassword(_staffId);
      _startCooldown();
      AppSnackbar.success(
        'forgot_code_sent_title'.tr,
        'forgot_code_sent_message'.tr,
      );
    } on ApiException catch (e) {
      _error(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (!otpFormKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    try {
      _resetToken = await _authService.verifyResetOtp(
        staffId: _staffId,
        otp: otpController.text.trim(),
      );
      step.value = 2;
    } on ApiException catch (e) {
      _error(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (!passwordFormKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    try {
      await _authService.resetPassword(
        resetToken: _resetToken,
        newPassword: newPasswordController.text,
      );
      Get.offAllNamed(Routes.login);
      AppSnackbar.success(
        'forgot_done_title'.tr,
        'forgot_done_message'.tr,
      );
    } on ApiException catch (e) {
      _error(e);
      // The reset session may have expired: go back to the start.
      if (e.statusCode == 400) step.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  /// Back arrow: one step back, or out to the login screen from the first.
  void back() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (step.value == 0) {
      Get.back();
    } else if (step.value == 1) {
      step.value = 0;
    } else {
      step.value = 1;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    staffIdController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
