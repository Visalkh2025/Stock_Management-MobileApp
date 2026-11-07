import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/more_controller.dart';
import 'package:stock_management/View/Components/app_main_scaffold.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/more_menu_row.dart';
import 'package:stock_management/View/Components/user_avatar.dart';

class MoreScreen extends GetView<MoreController> {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppMainScaffold(
      tab: AppNavTab.more,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.paddingOf(context).bottom * 0.5 + 76),
                children: [
                  _sectionLabel('section_management'.tr),
                  const SizedBox(height: 8),
                  Obx(() => _group([
                    MoreMenuRow(
                      icon: Icons.dns_outlined,
                      label: 'menu_manage'.tr,
                      onTap: controller.openManage,
                      trailing: Text(
                        'manage_subtitle'.tr,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
                      ),
                    ),
                    if (can(Perm.poView))
                    MoreMenuRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'menu_purchase_orders'.tr,
                      onTap: controller.openPurchaseOrders,
                      trailing: _countBadge(controller.purchaseOrderCount),
                    ),
                    MoreMenuRow(
                      icon: Icons.shopping_bag_outlined,
                      label: 'menu_customer_orders'.tr,
                      onTap: controller.openCustomerOrders,
                      trailing: _chevron,
                    ),
                    if (can(Perm.adjustmentView))
                    MoreMenuRow(
                      icon: Icons.history_rounded,
                      label: 'menu_stock_history'.tr,
                      onTap: controller.openStockHistory,
                      trailing: _chevron,
                    ),
                    if (can(Perm.reportView))
                    MoreMenuRow(
                      icon: Icons.bar_chart_rounded,
                      label: 'menu_reports'.tr,
                      onTap: controller.openReports,
                      trailing: _chevron,
                    ),
                    if (can(Perm.userView))
                    MoreMenuRow(
                      icon: Icons.groups_outlined,
                      label: 'menu_team_members'.tr,
                      onTap: controller.openTeamMembers,
                      trailing: _chevron,
                    ),
                    if (can(Perm.roleView))
                    MoreMenuRow(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'menu_roles_permissions'.tr,
                      onTap: controller.openRolesPermissions,
                      trailing: _chevron,
                    ),
                  ])),
                  const SizedBox(height: 18),
                  _sectionLabel('section_account'.tr),
                  const SizedBox(height: 8),
                  _group([
                    MoreMenuRow(
                      icon: Icons.settings_outlined,
                      label: 'menu_settings'.tr,
                      iconColor: AppColors.muted,
                      onTap: controller.openSettings,
                      trailing: _chevron,
                    ),
                    MoreMenuRow(
                      icon: Icons.help_outline_rounded,
                      label: 'menu_help_support'.tr,
                      iconColor: AppColors.muted,
                      onTap: controller.openHelpSupport,
                      trailing: _chevron,
                    ),
                  ]),
                  const SizedBox(height: 18),
                  _signOutButton,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // The profile summary row fills the spot the filter chips take on the
  // other list screens.
  Widget _header() {
    return AppScreenHeader(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'more_title'.tr,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
              ),
            ),
            _languageToggle,
          ],
        ),
        const SizedBox(height: 16),
        _profileRow,
      ],
    );
  }
  
  Widget get _languageToggle {
    return Obx(() {
      final isKhmer = controller.isKhmer;
      return Material(
        color: AppScreenHeader.onHeaderSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: controller.toggleLanguage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppScreenHeader.onHeaderSurfaceBorder),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isKhmer ? '\u{1F1F0}\u{1F1ED}' : '\u{1F1EC}\u{1F1E7}', style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  isKhmer ? 'language_khmer'.tr : 'EN',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppScreenHeader.onHeader),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget get _profileRow {
    return Obx(() {
      final profile = controller.profile;
      return Material(
        color: AppScreenHeader.onHeaderSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: controller.openProfile,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppScreenHeader.onHeaderSurfaceBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                UserAvatar(
                  profile: profile,
                  size: 46,
                  borderRadius: BorderRadius.circular(14),
                  backgroundColor: Colors.white,
                  initialsColor: AppColors.brand700,
                  initialsFontSize: 14,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppScreenHeader.onHeader),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${profile.role} • ${profile.email}',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: AppScreenHeader.onHeaderMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppScreenHeader.onHeaderMuted),
              ],
            ),
          ),
        ),
      );
    });
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

  Widget _countBadge(int count) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: AppColors.pageBg, borderRadius: BorderRadius.circular(7)),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted),
      ),
    );
  }

  Widget get _chevron => Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary);

  // Card-style row (matches the info/menu rows elsewhere) instead of a
  Widget get _signOutButton {
    return Material(
      color: AppColors.dangerBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: controller.signOut,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.danger.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(11)),
                alignment: Alignment.center,
                child: Icon(Icons.logout_rounded, size: 17, color: AppColors.danger),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'sign_out'.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.danger),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.danger.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
