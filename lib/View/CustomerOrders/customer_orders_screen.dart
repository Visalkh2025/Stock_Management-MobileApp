import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/customer_orders_controller.dart';
import 'package:stock_management/Model/customer_order_models.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/date_filter_bar.dart';
import 'package:stock_management/View/CustomerOrders/co_parts.dart';
import 'package:stock_management/View/PurchaseOrders/po_parts.dart';

/// More > Customer Orders — orders placed by customers (Mini App) or by staff,
/// with a status filter, a date filter and a search box.
/// See [CustomerOrdersController].
class CustomerOrdersScreen extends GetView<CustomerOrdersController> {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PoHeader(
            title: 'menu_customer_orders'.tr,
            below: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusChips,
                const SizedBox(height: 8),
                Obx(() => DateFilterBar(value: controller.dateFilter.value, onChanged: controller.setDateFilter)),
              ],
            ),
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
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    children: [
                      _searchField,
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        SizedBox(height: 280, child: _message(Icons.inventory_2_outlined, 'co_empty_state'.tr))
                      else
                        for (final order in items) ...[
                          _OrderCard(order: order, onTap: () => controller.openOrder(order)),
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

  Widget get _searchField {
    return TextField(
      onChanged: controller.setSearch,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'co_search_hint'.tr,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        isDense: true,
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
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
              for (final status in CoStatus.values) ...[
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
  // status keeps its own tint (same look as the Purchase Orders chips).
  Widget _chip(String label, int count, CoStatus? status) {
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
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final CustomerOrderSummary order;
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
                      order.orderNo,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ),
                  CoStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.customer.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
              if (order.customer.company != null && order.customer.company != order.customer.title) ...[
                const SizedBox(height: 2),
                Text(
                  order.customer.company!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                '${'po_items_count'.trParams({'count': '${order.itemCount}'})} • ${order.fromMiniApp ? 'co_source_miniapp'.tr : 'co_source_staff'.tr}',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    coMoney(order.totalAmount),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.brand700),
                  ),
                  const SizedBox(width: 8),
                  CoPaidBadge(order.isPaid),
                  const Spacer(),
                  Text(coDateTime(order.createdAt), style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
