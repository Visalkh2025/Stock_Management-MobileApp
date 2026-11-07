import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/customer_order_detail_controller.dart';
import 'package:stock_management/Model/customer_order_models.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/product_image_viewer.dart';
import 'package:stock_management/View/CustomerOrders/co_parts.dart';
import 'package:stock_management/View/PurchaseOrders/po_parts.dart';

/// One customer order: who ordered, what, how it was paid, its history, and
/// the next step its status allows (accept / reject, paid, deliver, complete).
class CustomerOrderDetailScreen extends GetView<CustomerOrderDetailController> {
  const CustomerOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Obx(() => PoHeader(title: controller.order.value?.orderNo ?? 'menu_customer_orders'.tr)),
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                final order = controller.order.value;
                if (order == null) {
                  if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        controller.errorMessage.value ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      _summary(order),
                      if (order.proofImageUrl != null) ...[
                        const SizedBox(height: 12),
                        _proofCard(order.proofImageUrl!),
                      ],
                      const SizedBox(height: 12),
                      _customerCard(order),
                      if (order.remark != null || order.staffNotes != null) ...[
                        const SizedBox(height: 12),
                        _notes(order),
                      ],
                      const SizedBox(height: 20),
                      PoSectionLabel('co_section_items'.tr),
                      const SizedBox(height: 10),
                      for (final item in order.items) ...[
                        _ItemCard(item: item, showApproved: order.status != CoStatus.pendingReview),
                        const SizedBox(height: 10),
                      ],
                      _totals(order),
                      if (order.messages.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        PoSectionLabel('co_section_history'.tr),
                        const SizedBox(height: 10),
                        _timeline(order.messages),
                      ],
                      const SizedBox(height: 16),
                      _actions,
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

  Widget _summary(CustomerOrderDetail order) {
    return PoCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  coMoney(order.totalAmount),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.brand700),
                ),
              ),
              CoStatusBadge(order.status),
            ],
          ),
          const SizedBox(height: 8),
          PoInfoRow('co_field_payment'.tr, order.isPaid ? 'co_paid'.tr : 'co_unpaid'.tr),
          if (order.isPaid && order.paidAt != null) PoInfoRow('co_field_paid_on'.tr, coDateTime(order.paidAt)),
          if (order.paidByName != null) PoInfoRow('co_field_received_by'.tr, order.paidByName!),
          PoInfoRow('co_field_delivery'.tr, (order.deliveryDone ? 'co_delivery_done' : 'co_delivery_pending').tr),
          PoInfoRow('co_field_source'.tr, (order.fromMiniApp ? 'co_source_miniapp' : 'co_source_staff').tr),
          PoInfoRow('po_created_on'.tr, coDateTime(order.createdAt)),
        ],
      ),
    );
  }

  /// The photo of the transaction attached to the payment; tap to open it full
  /// screen (pinch to zoom).
  Widget _proofCard(String url) {
    return PoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PoSectionLabel('co_section_proof'.tr),
          const SizedBox(height: 10),
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => showProductImageViewer(context, url: url, title: 'co_section_proof'.tr),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: url,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator(color: AppColors.brand700)),
                  ),
                  errorWidget: (_, _, _) => SizedBox(
                    height: 180,
                    child: Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textTertiary)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerCard(CustomerOrderDetail order) {
    final c = order.customer;
    return PoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PoSectionLabel('co_section_customer'.tr),
          const SizedBox(height: 8),
          PoInfoRow('co_field_name'.tr, c.title),
          if (c.company != null && c.company != c.title) PoInfoRow('co_field_company'.tr, c.company!),
          if (c.phone != null) _phoneRow(c.phone!),
          if (c.telegram != null) PoInfoRow('Telegram', c.telegram!),
          if (order.address != null) PoInfoRow('co_field_address'.tr, order.address!),
        ],
      ),
    );
  }

  /// Phone number with a copy button (to paste into the dialer).
  Widget _phoneRow(String phone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text('co_field_phone'.tr, style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              phone,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brand700),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => controller.copyPhone(phone),
            tooltip: 'co_copy_phone'.tr,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.copy_rounded, size: 18, color: AppColors.brand700),
          ),
        ],
      ),
    );
  }

  Widget _notes(CustomerOrderDetail order) {
    return PoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.remark != null) ...[
            Text('co_field_customer_note'.tr, style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(order.remark!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ],
          if (order.remark != null && order.staffNotes != null) const SizedBox(height: 10),
          if (order.staffNotes != null) ...[
            Text('co_field_staff_note'.tr, style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(order.staffNotes!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ],
        ],
      ),
    );
  }

  Widget _totals(CustomerOrderDetail order) {
    return PoCard(
      child: Column(
        children: [
          if (order.hasDiscount) ...[
            PoInfoRow('co_subtotal'.tr, coMoney(order.subtotalAmount)),
            PoInfoRow(
              order.tierName == null
                  ? 'co_discount'.tr
                  : '${'co_discount'.tr} (${order.tierName} ${coQty(order.discountPercent)}%)',
              '-${coMoney(order.discountAmount)}',
            ),
          ],
          PoInfoRow('co_total'.tr, coMoney(order.totalAmount)),
        ],
      ),
    );
  }

  Widget _timeline(List<CoMessage> messages) {
    return PoCard(
      child: Column(
        children: [
          for (var i = 0; i < messages.length; i++)
            _TimelineRow(message: messages[i], isLast: i == messages.length - 1),
        ],
      ),
    );
  }

  /// The error (if any) and the buttons the status allows.
  Widget get _actions {
    return Obx(() {
      final busy = controller.isBusy.value;
      final children = <Widget>[];

      void add(Widget w) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 10));
        children.add(w);
      }

      if (controller.canDecide) {
        add(AppButton(label: 'co_action_accept'.tr, icon: Icons.check_rounded, isLoading: busy, onPressed: controller.accept));
        add(AppButton(
          label: 'action_reject'.tr,
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: busy ? null : controller.reject,
        ));
      }
      if (controller.canMarkPaid) {
        add(AppButton(label: 'co_action_paid'.tr, icon: Icons.payments_outlined, isLoading: busy, onPressed: controller.markPaid));
      }
      if (controller.canProcess) {
        add(AppButton(label: 'co_action_process'.tr, icon: Icons.inventory_2_outlined, isLoading: busy, onPressed: controller.process));
      }
      if (controller.canDeliver) {
        add(AppButton(label: 'co_action_out'.tr, icon: Icons.local_shipping_outlined, isLoading: busy, onPressed: controller.outForDelivery));
      }
      if (controller.canMarkDelivered) {
        add(AppButton(label: 'co_action_delivered'.tr, icon: Icons.task_alt_rounded, isLoading: busy, onPressed: controller.delivered));
      }
      if (controller.canComplete) {
        add(AppButton(label: 'co_action_complete'.tr, icon: Icons.verified_outlined, isLoading: busy, onPressed: controller.complete));
      }

      final error = controller.errorMessage.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) PoErrorBanner(error),
          ...children,
        ],
      );
    });
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.showApproved});

  final CoItem item;

  /// After the review, show what was approved / is still waiting.
  final bool showApproved;

  @override
  Widget build(BuildContext context) {
    final differs = showApproved && item.approved != item.requested;
    return PoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 8),
              Text(coMoney(item.subtotal), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${coQty(item.requested)} × ${coMoney(item.unitPrice)}',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          if (differs || item.waiting > 0) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (differs) '${'co_approved'.tr}: ${coQty(item.approved)}',
                if (item.waiting > 0) '${'co_waiting'.tr}: ${coQty(item.waiting)}',
              ].join(' • '),
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.warning),
            ),
          ],
          if (item.warehouseName != null) ...[
            const SizedBox(height: 2),
            Text(item.warehouseName!, style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
          ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.message, required this.isLast});

  final CoMessage message;
  final bool isLast;

  Color get _dot {
    switch (message.sender) {
      case 'CUSTOMER':
        return AppColors.warning;
      case 'STAFF':
        return AppColors.brand700;
      default:
        return AppColors.muted;
    }
  }

  String get _who {
    if (message.senderName != null) return message.senderName!;
    switch (message.sender) {
      case 'CUSTOMER':
        return 'co_sender_customer'.tr;
      case 'STAFF':
        return 'co_sender_staff'.tr;
      default:
        return 'co_sender_system'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(width: 10, height: 10, decoration: BoxDecoration(color: _dot, shape: BoxShape.circle)),
                if (!isLast) Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.message, style: TextStyle(fontSize: 13, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(
                    '$_who • ${coDateTime(message.createdAt)}',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
