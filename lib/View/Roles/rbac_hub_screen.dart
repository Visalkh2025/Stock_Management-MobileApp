import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/permissions_controller.dart';
import 'package:stock_management/Controller/rbac_hub_controller.dart';
import 'package:stock_management/Controller/roles_controller.dart';
import 'package:stock_management/Model/rbac_models.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/swipe_actions.dart';

/// More > Roles & Permissions. A single hub screen with two tabs — Roles
/// (role identity + the permissions it grants) and Permissions (the
/// system-wide capability catalog those grants are drawn from) — the
/// mobile stand-in for what the web app splits across two full pages.
/// Also replaces the web's separate "Category Matrix" tab: the
/// Permissions tab here is always grouped by category, so there's no
/// second, redundant view of the same handful of rows.
class RbacHubScreen extends GetView<RbacHubController> {
  const RbacHubScreen({super.key});

  RolesController get _roles {
    if (!Get.isRegistered<RolesController>()) {
      Get.put(RolesController(), permanent: true);
    }
    return Get.find<RolesController>();
  }

  PermissionsController get _permissions {
    if (!Get.isRegistered<PermissionsController>()) {
      Get.put(PermissionsController(), permanent: true);
    }
    return Get.find<PermissionsController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header,
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                return controller.selectedTab.value == RbacTab.roles
                    ? _rolesTab(context)
                    : _permissionsTab(context);
              }),
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
            Expanded(
              child: Text(
                'menu_roles_permissions'.tr,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
              ),
            ),
            Obx(() {
              final isRoles = controller.selectedTab.value == RbacTab.roles;
              return Material(
                color: AppScreenHeader.onHeaderSurface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: isRoles ? _roles.openAdd : _permissions.openAdd,
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(Icons.add_rounded, size: 20, color: AppScreenHeader.onHeader),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 14),
        _tabSwitcher,
        const SizedBox(height: 12),
        _searchField,
      ],
    );
  }

  Widget get _searchField {
    return Obx(() {
      final isRoles = controller.selectedTab.value == RbacTab.roles;
      return Container(
        height: 42,
        decoration: BoxDecoration(color: AppScreenHeader.onHeaderSurface, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 12),
        child: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_rounded, size: 18, color: AppScreenHeader.onHeaderMuted),
              const SizedBox(width: 8),
              IntrinsicWidth(
                child: TextField(
                  key: ValueKey(isRoles),
                  onChanged: isRoles ? _roles.setSearch : _permissions.setSearch,
                  style: const TextStyle(fontSize: 13.5, color: Colors.white),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: isRoles ? 'search_roles'.tr : 'search_permissions'.tr,
                    hintStyle: const TextStyle(color: AppScreenHeader.onHeaderMuted, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget get _tabSwitcher {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppScreenHeader.onHeaderSurface, borderRadius: BorderRadius.circular(12)),
      child: Obx(
        () => Row(
          children: [
            Expanded(child: _tabButton('tab_roles'.tr, RbacTab.roles)),
            Expanded(child: _tabButton('tab_permissions'.tr, RbacTab.permissions)),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, RbacTab tab) {
    final isActive = controller.selectedTab.value == tab;
    return Material(
      color: isActive ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: () => controller.selectTab(tab),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.brand700 : AppScreenHeader.onHeaderMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
    );
  }

  // ---------------------------------------------------------------------
  // Roles tab
  // ---------------------------------------------------------------------

  Widget _rolesTab(BuildContext context) {
    return Obx(() {
      final items = _roles.filteredItems;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          if (items.isEmpty)
            _emptyState(
              icon: Icons.admin_panel_settings_outlined,
              title: 'empty_roles_title'.tr,
              subtitle: 'empty_roles_hint'.tr,
            )
          else
            for (final role in items) ...[
              _roleCard(context, role),
              const SizedBox(height: 12),
            ],
        ],
      );
    });
  }

  Widget _roleCard(BuildContext context, RoleData role) {
    return AppSwipeActions(
      borderRadius: BorderRadius.circular(18),
      onEdit: () => _roles.openEdit(role),
      onDelete: () => _confirmDeleteRole(context, role),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  role.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'permission_count_badge'.trParams({
                    'count': '${role.permissionCodes.length}',
                    'word': (role.permissionCodes.length == 1 ? 'unit_permission' : 'unit_permissions').tr,
                  }),
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.brand700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(role.description, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted)),
          const SizedBox(height: 14),
          _sectionLabel('section_assigned_permissions'.tr),
          const SizedBox(height: 8),
          if (role.permissionCodes.isEmpty)
            Text(
              'no_permissions_assigned_yet'.tr,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textTertiary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in role.permissionCodes) _permissionChip(role, code),
              ],
            ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 12),
          AppButton(
            label: 'action_manage_permissions'.tr,
            icon: Icons.tune_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: () => _roles.openPermissions(role),
          ),
        ],
      ),
    ));
  }

  Widget _permissionChip(RoleData role, String code) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brand700)),
          InkWell(
            onTap: () => _roles.removePermission(role, code),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 13, color: AppColors.brand700),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRole(BuildContext context, RoleData role) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('delete_role_title'.tr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'delete_role_message'.trParams({'name': role.name}),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('action_cancel'.tr, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _roles.delete(role);
            },
            child: Text('action_delete'.tr, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Permissions tab
  // ---------------------------------------------------------------------

  Widget _permissionsTab(BuildContext context) {
    return Obx(() {
      final grouped = _permissions.groupedByCategory;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          if (grouped.isEmpty)
            _emptyState(
              icon: Icons.vpn_key_outlined,
              title: 'empty_permissions_title'.tr,
              subtitle: 'empty_permissions_hint'.tr,
            )
          else
            for (final entry in grouped.entries) ...[
              _categoryGroup(context, entry.key, entry.value),
              const SizedBox(height: 18),
            ],
        ],
      );
    });
  }

  Widget _categoryGroup(BuildContext context, String category, List<PermissionData> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 14, decoration: BoxDecoration(color: AppColors.brand600, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(
              category.isEmpty ? 'uncategorized_label'.tr : category,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < items.length; i++) ...[
          _permissionRow(context, items[i]),
          if (i != items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _permissionRow(BuildContext context, PermissionData item) {
    return AppSwipeActions(
      borderRadius: BorderRadius.circular(14),
      onEdit: () => _permissions.openEdit(item),
      onDelete: () => _confirmDeletePermission(context, item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      item.code,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.brand700),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(item.description, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePermission(BuildContext context, PermissionData item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('delete_permission_title'.tr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'delete_permission_message'.trParams({'code': item.code}),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('action_cancel'.tr, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _permissions.delete(item);
            },
            child: Text('action_delete'.tr, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
