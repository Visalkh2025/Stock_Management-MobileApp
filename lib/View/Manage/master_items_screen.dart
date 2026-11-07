import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/master_items_controller.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/master_data_parts.dart';
import 'package:stock_management/View/Components/product_image.dart';

/// Manage > (Category | Brand | Supplier | Warehouse) > products of that one.
/// A row on the Manage lists opens this; a second row of chips narrows the
/// products (a category by brand, anything else by category).
class MasterItemsScreen extends GetView<MasterItemsController> {
  const MasterItemsScreen({super.key});

  String get _hintKey {
    switch (controller.args.kind) {
      case MasterKind.category:
        return 'master_items_hint_category';
      case MasterKind.brand:
        return 'master_items_hint_brand';
      case MasterKind.supplier:
        return 'master_items_hint_supplier';
      case MasterKind.warehouse:
        return 'master_items_hint_warehouse';
    }
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
                final loading = controller.isLoading;
                final error = controller.errorMessage;
                final members = controller.members;
                final items = controller.items;
                final facets = controller.facets;
                return RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      if (loading && members.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (error != null && members.isEmpty)
                        MasterListError(message: error, onRetry: controller.refresh)
                      else ...[
                        _summary(members.length),
                        if (facets.length > 1) ...[
                          const SizedBox(height: 14),
                          _facetChips(facets, members.length),
                        ],
                        const SizedBox(height: 14),
                        if (items.isEmpty)
                          _emptyState
                        else
                          for (final item in items) ...[
                            _itemCard(item),
                            const SizedBox(height: 10),
                          ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.args.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _hintKey.tr,
                    style: const TextStyle(fontSize: 11.5, color: AppScreenHeader.onHeaderMuted),
                  ),
                ],
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
                  hintText: 'master_items_search'.tr,
                  hintStyle: const TextStyle(color: AppScreenHeader.onHeaderMuted, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(int count) {
    final attention = controller.attentionCount;
    return Row(
      children: [
        Expanded(child: _statTile('master_items_products'.tr, '$count', AppColors.brand700)),
        const SizedBox(width: 10),
        Expanded(child: _statTile('master_items_units'.tr, '${controller.totalUnits}', AppColors.ink)),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            'master_items_attention'.tr,
            '$attention',
            attention > 0 ? AppColors.warning : AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _facetChips(List<MasterFacet> facets, int total) {
    final selected = controller.selectedFacet.value;
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('master_items_all'.tr, total, selected == null, () => controller.select(null)),
          for (final f in facets) ...[
            const SizedBox(width: 8),
            _chip(f.label, f.count, selected == f.key, () => controller.select(f.key)),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, int count, bool active, VoidCallback onTap) {
    return Material(
      color: active ? AppColors.brand700 : AppColors.cardBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? AppColors.brand700 : AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            '$label  $count',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget get _emptyState {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(
            'master_items_empty'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Color _statusColor(StockStatus s) {
    switch (s) {
      case StockStatus.inStock:
        return AppColors.success;
      case StockStatus.lowStock:
        return AppColors.warning;
      case StockStatus.outOfStock:
        return AppColors.danger;
    }
  }

  Color _statusBg(StockStatus s) {
    switch (s) {
      case StockStatus.inStock:
        return AppColors.successBg;
      case StockStatus.lowStock:
        return AppColors.warningBg;
      case StockStatus.outOfStock:
        return AppColors.dangerBg;
    }
  }

  Widget _itemCard(StockItemData item) {
    final qty = controller.quantityOf(item);
    final location = controller.locationOf(item);
    final purchase = controller.purchaseOf(item);
    final sub = [
      item.sku,
      if (controller.args.kind != MasterKind.category && (item.category ?? '').isNotEmpty) item.category!,
      if (controller.args.kind != MasterKind.brand && (item.brand ?? '').isNotEmpty) item.brand!,
    ].where((e) => e.isNotEmpty).join(' • ');
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => controller.open(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ProductImage(url: item.imageUrl, size: 46, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                    ),
                    if (purchase != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'master_items_bought'.trParams({'n': '${purchase.orders}', 'price': purchase.lastPrice.toStringAsFixed(2)}),
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.brand700),
                      ),
                    ],
                    if (location != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 3),
                          Text(location, style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$qty',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _statusBg(item.status), borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      item.status.label,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _statusColor(item.status)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
