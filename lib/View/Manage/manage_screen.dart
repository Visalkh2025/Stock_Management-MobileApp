import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/manage_controller.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/more_menu_row.dart';

/// Behind More > Manage and Home's "Manage" quick action.
class ManageScreen extends GetView<ManageController> {
  const ManageScreen({super.key});

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
                  Obx(
                    () => _group([
                      MoreMenuRow(
                        icon: Icons.category_outlined,
                        label: 'menu_categories'.tr,
                        onTap: controller.openCategories,
                        trailing: _countBadge(controller.categoryCount),
                      ),
                      MoreMenuRow(
                        icon: Icons.sell_outlined,
                        label: 'menu_brands'.tr,
                        onTap: controller.openBrands,
                        trailing: _countBadge(controller.brandCount),
                      ),
                      MoreMenuRow(
                        icon: Icons.local_shipping_outlined,
                        label: 'menu_suppliers'.tr,
                        onTap: controller.openSuppliers,
                        trailing: _countBadge(controller.supplierCount),
                      ),
                      MoreMenuRow(
                        icon: Icons.warehouse_outlined,
                        label: 'menu_warehouses'.tr,
                        onTap: controller.openWarehouses,
                        trailing: _countBadge(controller.warehouseCount),
                      ),
                    ]),
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
              'menu_manage'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
            ),
          ],
        ),
      ],
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
      child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
    );
  }
}
