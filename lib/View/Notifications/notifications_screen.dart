import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/notifications_controller.dart';
import 'package:stock_management/Model/customer_order_models.dart';
import 'package:stock_management/View/PurchaseOrders/po_parts.dart';

/// Orders waiting for review. See [NotificationsController].
class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PoHeader(title: 'notifications_title'.tr),
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                final items = controller.orders;
                final error = controller.errorMessage.value;
                if (controller.isLoading.value && items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      if (error != null && items.isEmpty)
                        _message(Icons.error_outline_rounded, error)
                      else if (items.isEmpty)
                        _message(Icons.notifications_none_rounded, 'notifications_empty'.tr)
                      else ...[
                        Text(
                          '${'notifications_section'.tr} (${items.length})',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
                        ),
                        const SizedBox(height: 10),
                        for (final order in items) ...[
                          _NotificationTile(order: order, onTap: () => controller.openOrder(order)),
                          const SizedBox(height: 10),
                        ],
                      ],
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: controller.openAllOrders,
                        child: Text('notifications_view_all'.tr),
                      ),
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

  Widget _message(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 12),
      child: Column(
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
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.order, required this.onTap});

  final CustomerOrderSummary order;
  final VoidCallback onTap;

  static String _ago(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'time_just_now'.tr;
    if (diff.inMinutes < 60) return 'time_minutes_ago'.trParams({'n': '${diff.inMinutes}'});
    if (diff.inHours < 24) return 'time_hours_ago'.trParams({'n': '${diff.inHours}'});
    return 'time_days_ago'.trParams({'n': '${diff.inDays}'});
  }

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
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(13)),
                child: Icon(Icons.shopping_bag_outlined, size: 20, color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'notifications_new_order'.trParams({'no': order.orderNo}),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.customer.title} • ${'po_items_count'.trParams({'count': '${order.itemCount}'})} • ${coMoney(order.totalAmount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(_ago(order.createdAt), style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}
