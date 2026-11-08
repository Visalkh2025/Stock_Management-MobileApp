import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/customers_controller.dart';
import 'package:stock_management/Model/customer_models.dart';
import 'package:stock_management/Model/customer_order_models.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Customers/customer_parts.dart';
import 'package:stock_management/View/PurchaseOrders/po_parts.dart';

/// More > Customers — every registered customer with a status filter and a
/// search box. See [CustomersController].
class CustomersScreen extends GetView<CustomersController> {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PoHeader(title: 'menu_customers'.tr, below: _statusChips),
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                if (controller.isLoading.value && controller.customers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final error = controller.errorMessage.value;
                if (error != null && controller.customers.isEmpty) return _message(Icons.error_outline_rounded, error);
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
                        SizedBox(height: 280, child: _message(Icons.groups_outlined, 'cu_empty_state'.tr))
                      else
                        for (final customer in items) ...[
                          _CustomerCard(customer: customer, onTap: () => controller.openCustomer(customer)),
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
        hintText: 'cu_search_hint'.tr,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _chip('filter_all'.tr, controller.totalCount, null),
            for (final status in CustomerStatus.values) ...[
              const SizedBox(width: 8),
              _chip(status.labelKey.tr, controller.countFor(status), status),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, int count, CustomerStatus? status) {
    final isActive = controller.activeFilter.value == status;
    return Material(
      color: isActive ? Colors.white : AppScreenHeader.onHeaderSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => controller.setFilter(status),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            '$label  $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.brand700 : AppScreenHeader.onHeader,
            ),
          ),
        ),
      ),
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

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onTap});

  final CustomerRow customer;
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
                      customer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomerStatusBadge(customer.status),
                ],
              ),
              if (customer.company != null && customer.company != customer.title) ...[
                const SizedBox(height: 2),
                Text(
                  customer.company!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                [customer.phone, customer.telegram].whereType<String>().join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    coMoney(customer.totalSpent),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.brand700),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'cu_orders_count'.trParams({'count': '${customer.orderCount}'}),
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  if (customer.tierName != null) ...[
                    const SizedBox(width: 8),
                    CustomerTierChip(customer.tierName!),
                  ],
                  const Spacer(),
                  if (customer.lastOrderAt != null)
                    Text(coDateTime(customer.lastOrderAt), style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
