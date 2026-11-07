import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_management/Config/theme/app_theme.dart';

/// App-wide appearance (System / Light / Dark), persisted across restarts.
class ThemeController extends GetxController with WidgetsBindingObserver {
  static const _prefsKey = 'app_theme_mode';

  final mode = ThemeMode.system.obs;

  bool get isDark => AppColors.isDark;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  bool _resolveDark() {
    switch (mode.value) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return ui.PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
  }

  /// Reads the saved choice (if any). Awaited in main() before runApp so the
  /// very first frame already uses the right colours.
  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_prefsKey)) {
      case 'dark':
        mode.value = ThemeMode.dark;
      case 'light':
        mode.value = ThemeMode.light;
      default:
        mode.value = ThemeMode.system;
    }
    AppColors.isDark = _resolveDark();
  }

  Future<void> setMode(ThemeMode newMode) async {
    if (mode.value == newMode) return;
    mode.value = newMode;
    AppColors.isDark = _resolveDark();
    Get.changeThemeMode(newMode);
    _rebuildEverything();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newMode == ThemeMode.dark ? 'dark' : (newMode == ThemeMode.light ? 'light' : 'system'));
  }

  // The OS flipped light/dark while the app is open and we follow the system.
  @override
  void didChangePlatformBrightness() {
    if (mode.value != ThemeMode.system) return;
    final dark = _resolveDark();
    if (dark == AppColors.isDark) return;
    AppColors.isDark = dark;
    _rebuildEverything();
  }

  void _rebuildEverything() {
    WidgetsBinding.instance.addPostFrameCallback((_) => Get.forceAppUpdate());
  }
}
