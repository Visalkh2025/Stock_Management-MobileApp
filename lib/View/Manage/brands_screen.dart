import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/brand_controller.dart';
import 'package:stock_management/Model/master_data_models.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/master_data_parts.dart';
import 'package:stock_management/View/Components/swipe_actions.dart';

/// Manage > Brands — flat searchable list, "+Add" in the header, and
/// an edit/delete action on each row. Add/Edit both land on
/// BrandFormScreen (see BrandController.openAdd/openEdit).
class BrandsScreen extends GetView<BrandController> {
  const BrandsScreen({super.key});

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
                final items = controller.filteredItems;
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      if (controller.isLoading.value && items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (controller.errorMessage.value != null && items.isEmpty)
                        MasterListError(message: controller.errorMessage.value!, onRetry: controller.load)
                      else if (items.isEmpty)
                        _emptyState
                      else
                        for (final item in items) ...[
                          _brandCard(context, item),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
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
                'menu_brands'.tr,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
              ),
            ),
            if (can(Perm.brandManage)) Material(
              color: AppScreenHeader.onHeaderSurface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: controller.openAdd,
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(Icons.add_rounded, size: 20, color: AppScreenHeader.onHeader),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _searchField,
      ],
    );
  }

  Widget get _searchField {
    return Container(
      height: 42,
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(color: AppScreenHeader.onHeaderSurface, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.centerLeft,
      // prefixIcon pins the icon to the field's far-left edge, leaving a gap
      // before the hint — IntrinsicWidth shrinks the icon+field group to its
      // content instead, so the hint sits right next to the icon, same as
      // the search bar on Team Members/Roles & Permissions.
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_rounded, size: 18, color: AppScreenHeader.onHeaderMuted),
            const SizedBox(width: 8),
            IntrinsicWidth(
              child: TextField(
                onChanged: controller.setSearch,
                style: const TextStyle(fontSize: 13.5, color: Colors.white),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: 'search_brands'.tr,
                  hintStyle: const TextStyle(color: AppScreenHeader.onHeaderMuted, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandCard(BuildContext context, BrandData item) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Icon(Icons.sell_outlined, size: 17, color: AppColors.brand700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                if ((item.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description!,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    if (!can(Perm.brandManage)) return card;
    return AppSwipeActions(
      borderRadius: BorderRadius.circular(16),
      onEdit: () => controller.openEdit(item),
      onDelete: () => _confirmDelete(context, item),
      child: card,
    );
  }

  void _confirmDelete(BuildContext context, BrandData item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('delete_brand_title'.tr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'delete_brand_message'.trParams({'name': item.name}),
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
              controller.delete(item);
            },
            child: Text('action_delete'.tr, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget get _emptyState {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(Icons.sell_outlined, size: 36, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text('empty_brands_title'.tr, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text('empty_brands_hint'.tr, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
