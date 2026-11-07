import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/settings_controller.dart';
import 'package:stock_management/Controller/theme_controller.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/more_menu_row.dart';

/// More > Settings — grouped preference toggles + account-security
/// shortcuts, styled as the same card-group pattern as the More screen
/// itself (MoreMenuRow, section labels, grouped cards).
class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header,
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  _sectionLabel('section_notifications'.tr),
                  const SizedBox(height: 8),
                  Obx(
                    () => _group([
                      MoreMenuRow(
                        icon: Icons.notifications_outlined,
                        label: 'push_notifications'.tr,
                        trailing: _switch(controller.pushNotifications.value, controller.togglePushNotifications),
                      ),
                      MoreMenuRow(
                        icon: Icons.warning_amber_rounded,
                        label: 'low_stock_alerts'.tr,
                        trailing: _switch(controller.lowStockAlerts.value, controller.toggleLowStockAlerts),
                      ),
                      MoreMenuRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'weekly_email_report'.tr,
                        trailing: _switch(controller.weeklyEmailReport.value, controller.toggleWeeklyEmailReport),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  _sectionLabel('section_security'.tr),
                  const SizedBox(height: 8),
                  Obx(
                    () => _group([
                      MoreMenuRow(
                        icon: Icons.fingerprint_rounded,
                        label: 'biometric_login'.tr,
                        iconColor: AppColors.muted,
                        trailing: _switch(controller.biometricLogin.value, controller.toggleBiometricLogin),
                      ),
                      MoreMenuRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'change_password'.tr,
                        iconColor: AppColors.muted,
                        onTap: controller.changePassword,
                        trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  _sectionLabel('section_appearance'.tr),
                  const SizedBox(height: 8),
                  Obx(() {
                    final theme = Get.find<ThemeController>();
                    return _group([
                      MoreMenuRow(
                        icon: Icons.brightness_auto_rounded,
                        label: 'theme_system'.tr,
                        iconColor: AppColors.muted,
                        onTap: () => theme.setMode(ThemeMode.system),
                        trailing: _languageCheck(theme.mode.value == ThemeMode.system),
                      ),
                      MoreMenuRow(
                        icon: Icons.light_mode_outlined,
                        label: 'theme_light'.tr,
                        iconColor: AppColors.muted,
                        onTap: () => theme.setMode(ThemeMode.light),
                        trailing: _languageCheck(theme.mode.value == ThemeMode.light),
                      ),
                      MoreMenuRow(
                        icon: Icons.dark_mode_outlined,
                        label: 'theme_dark'.tr,
                        iconColor: AppColors.muted,
                        onTap: () => theme.setMode(ThemeMode.dark),
                        trailing: _languageCheck(theme.mode.value == ThemeMode.dark),
                      ),
                    ]);
                  }),
                  const SizedBox(height: 18),
                  _sectionLabel('section_language'.tr),
                  const SizedBox(height: 8),
                  Obx(
                    () => _group([
                      MoreMenuRow(
                        icon: Icons.language_rounded,
                        label: 'language_english'.tr,
                        iconColor: AppColors.muted,
                        onTap: () => controller.setLanguage('en'),
                        trailing: _languageCheck(!controller.isKhmer),
                      ),
                      MoreMenuRow(
                        icon: Icons.language_rounded,
                        label: 'language_khmer'.tr,
                        iconColor: AppColors.muted,
                        onTap: () => controller.setLanguage('km'),
                        trailing: _languageCheck(controller.isKhmer),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'StockFlow v1.0.0',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            Text(
              'settings_title'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
    );
  }

  Widget _group(List<Widget> rows) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.brand900.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(height: 1, thickness: 1, color: AppColors.border, indent: 14, endIndent: 14),
          ],
        ],
      ),
    );
  }

  // No onTap on rows that use this — the switch's own onChanged handles
  // the toggle, so the row itself stays non-tappable to avoid a double
  // toggle from InkWell + Switch both reacting to the same tap.
  Widget _switch(bool value, ValueChanged<bool> onChanged) {
    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.brand600,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: AppColors.border,
      ),
    );
  }

  // A plain check mark when a language row is the active one, otherwise
  // nothing — these rows use onTap (not a Switch) since only one of the
  // two can ever be selected at a time.
  Widget _languageCheck(bool selected) {
    return selected
        ? const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.brand600)
        : const SizedBox(width: 20, height: 20);
  }
}
