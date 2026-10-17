import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/locale_controller.dart';

/// More > Settings — a handful of UI-only preference toggles (no backend
/// to persist them yet, same "demo" shape as the rest of the app) plus a
/// couple of account-security shortcuts and the app language switch.
class SettingsController extends GetxController {
  final pushNotifications = true.obs;
  final lowStockAlerts = true.obs;
  final weeklyEmailReport = false.obs;
  final biometricLogin = false.obs;

  void togglePushNotifications(bool value) => pushNotifications.value = value;
  void toggleLowStockAlerts(bool value) => lowStockAlerts.value = value;
  void toggleWeeklyEmailReport(bool value) => weeklyEmailReport.value = value;
  void toggleBiometricLogin(bool value) => biometricLogin.value = value;

  // Registered permanently in main() before runApp — same guarded-singleton
  // pattern used everywhere else in this app for cross-controller access.
  LocaleController get _locale {
    if (!Get.isRegistered<LocaleController>()) {
      Get.put(LocaleController(), permanent: true);
    }
    return Get.find<LocaleController>();
  }

  bool get isKhmer => _locale.isKhmer;

  void setLanguage(String languageCode) => _locale.changeLocale(languageCode);

  void changePassword() {
    Get.snackbar(
      'change_password_title'.tr,
      'change_password_body'.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
