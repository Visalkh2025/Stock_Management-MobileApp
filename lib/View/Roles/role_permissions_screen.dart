import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/role_permissions_controller.dart';
import 'package:stock_management/Model/rbac_models.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';

/// The full permission catalog as a checklist, grouped by category —
/// reached from a role card's "Manage permissions" button. Pre-checked
/// from that role's current grants; Save replaces its whole permission
/// set with whatever's checked. See [RolePermissionsController].
class RolePermissionsScreen extends GetView<RolePermissionsController> {
  const RolePermissionsScreen({super.key});

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
                final grouped = controller.groupedByCategory;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    Text(
                      'granted_count_label'.trParams({
                        'selected': '${controller.selectedCodes.length}',
                        'total': '${grouped.values.fold(0, (sum, list) => sum + list.length)}',
                      }),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),
                    for (final entry in grouped.entries) ...[
                      _categoryGroup(entry.key, entry.value),
                      const SizedBox(height: 18),
                    ],
                    AppButton(label: 'action_save_permissions'.tr, onPressed: controller.save),
                  ],
                );
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
                controller.role.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'action_manage_permissions'.tr,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppScreenHeader.onHeaderMuted),
        ),
      ],
    );
  }

  Widget _categoryGroup(String category, List<PermissionData> items) {
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
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _permissionCheckRow(items[i]),
                if (i != items.length - 1)
                  const Divider(height: 1, thickness: 1, color: AppColors.border, indent: 14, endIndent: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _permissionCheckRow(PermissionData item) {
    return InkWell(
      onTap: () => controller.toggle(item.code),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.code, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(item.description, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Checkbox(
              value: controller.isSelected(item.code),
              onChanged: (_) => controller.toggle(item.code),
              activeColor: AppColors.brand600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ],
        ),
      ),
    );
  }
}
