import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/customer_detail_controller.dart';
import 'package:stock_management/Model/customer_models.dart';
import 'package:stock_management/Model/customer_order_models.dart';
import 'package:stock_management/View/CustomerOrders/co_parts.dart';
import 'package:stock_management/View/Customers/customer_parts.dart';
import 'package:stock_management/View/PurchaseOrders/po_parts.dart';

/// More > Customers > one customer: contact info, order totals and every order
/// they placed (tap one to open it). See [CustomerDetailController].
class CustomerDetailScreen extends GetView<CustomerDetailController> {
  const CustomerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PoHeader(title: 'cu_detail_title'.tr),
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                final customer = controller.customer.value;
                if (controller.isLoading.value && customer == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final error = controller.errorMessage.value;
                if (customer == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        error ?? '—',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                      ),
                    ),
                  );
                }
                final orders = controller.orders;
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      if (error != null) PoErrorBanner(error),
                      _summary(customer),
                      const SizedBox(height: 14),
                      _stats(customer),
                      const SizedBox(height: 14),
                      _contact(customer),
                      const SizedBox(height: 18),
                      PoSectionLabel('${'cu_orders_section'.tr} (${orders.length})'),
                      const SizedBox(height: 10),
                      if (orders.isEmpty)
                        PoCard(
                          child: Text('cu_no_orders'.tr, style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
                        )
                      else
                        for (final order in orders) ...[
                          _OrderTile(order: order, onTap: () => controller.openOrder(order)),
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

  Widget _summary(CustomerRow c) {
    return PoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          if (c.company != null && c.company != c.title) ...[
            const SizedBox(height: 2),
            Text(c.company!, style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CustomerStatusBadge(c.status),
              if (c.tierName != null) CustomerTierChip(c.tierName!),
              if (c.discountPercent > 0)
                Text(
                  'cu_discount'.trParams({'percent': coQty(c.discountPercent)}),
                  style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                ),
            ],
          ),
          if (c.status == CustomerStatus.rejected && c.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Text(c.rejectionReason!, style: TextStyle(fontSize: 12, color: AppColors.danger)),
          ],
        ],
      ),
    );
  }

  Widget _stats(CustomerRow c) {
    Widget cell(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
              const SizedBox(height: 3),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ],
          ),
        );
    return PoCard(
      child: Column(
        children: [
          Row(
            children: [
              cell('cu_total_orders'.tr, '${c.orderCount}'),
              cell('cu_completed'.tr, '${c.completedOrders}'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              cell('cu_total_spent'.tr, coMoney(c.totalSpent)),
              cell('cu_units'.tr, coQty(c.totalQuantity)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contact(CustomerRow c) {
    return PoCard(
      child: Column(
        children: [
          PoInfoRow('cu_contact_name'.tr, c.name ?? '—'),
          PoInfoRow('cu_company'.tr, c.company ?? '—'),
          PoInfoRow('cu_phone'.tr, c.phone ?? '—'),
          PoInfoRow('cu_telegram'.tr, c.telegramAccounts.isEmpty ? (c.telegram ?? '—') : c.telegramAccounts.join(', ')),
          PoInfoRow('cu_address'.tr, c.address ?? '—'),
          PoInfoRow('cu_last_order'.tr, c.lastOrderAt == null ? '—' : coDateTime(c.lastOrderAt)),
          PoInfoRow('cu_registered'.tr, c.joinedAt == null ? '—' : coDateTime(c.joinedAt)),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

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
          padding: const EdgeInsets.all(14),
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
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ),
                  CoStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    coMoney(order.totalAmount),
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.brand700),
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
