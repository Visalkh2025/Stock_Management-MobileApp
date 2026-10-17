import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/purchase_orders_controller.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/PurchaseOrders/po_parts.dart';

/// More > Purchase Orders — every purchase order with a status filter.
/// See [PurchaseOrdersController].
class PurchaseOrdersScreen extends GetView<PurchaseOrdersController> {
  const PurchaseOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PoHeader(
            title: 'menu_purchase_orders'.tr,
            trailing: can(Perm.poCreate) ? _addButton : null,
            below: _statusChips,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                if (controller.isLoading.value && controller.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final error = controller.errorMessage.value;
                if (error != null && controller.orders.isEmpty) return _message(Icons.error_outline_rounded, error);
                final items = controller.filteredItems;
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: items.isEmpty
                      ? ListView(children: [SizedBox(height: 320, child: _message(Icons.receipt_long_outlined, 'purchase_orders_empty_state'.tr))])
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                          itemCount: items.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) => _OrderCard(
                            order: items[index],
                            onTap: () => controller.openOrder(items[index]),
                          ),
                        ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _addButton {
    return Material(
      color: AppScreenHeader.onHeaderSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: controller.createOrder,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(Icons.add_rounded, size: 20, color: AppScreenHeader.onHeader),
        ),
      ),
    );
  }

  Widget get _statusChips {
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _chip('filter_all'.tr, controller.totalCount, null),
              for (final status in PoStatus.values) ...[
                const SizedBox(width: 10),
                _chip(status.labelKey.tr, controller.countFor(status), status),
              ],
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  // Count as a small circular badge in the pill's top-right corner; each
  // status keeps its own tint.
  Widget _chip(String label, int count, PoStatus? status) {
    final isActive = controller.activeFilter.value == status;
    Color bg;
    Color fg;
    if (isActive) {
      bg = Colors.white;
      fg = AppColors.brand700;
    } else if (status == null) {
      bg = AppScreenHeader.onHeaderSurface;
      fg = AppScreenHeader.onHeader;
    } else {
      bg = status.background;
      fg = status.color;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => controller.setFilter(status),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                border: isActive || status != null ? null : Border.all(color: AppScreenHeader.onHeaderSurfaceBorder),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18),
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: fg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: !isActive && status == null ? AppColors.brand700 : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _message(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final PurchaseOrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.poNumber,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ),
                  PoStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.supplierName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
              const SizedBox(height: 2),
              Text(
                '${'po_items_count'.trParams({'count': '${order.itemCount}'})} • ${order.warehouseName}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              if (order.pendingCatalogCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'po_list_pending'.trParams({'count': '${order.pendingCatalogCount}'}),
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.warning),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    formatMoney(order.totalAmount),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.brand700),
                  ),
                  const Spacer(),
                  Text(formatDate(order.createdAt), style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
