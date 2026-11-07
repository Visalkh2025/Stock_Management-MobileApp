import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/purchase_order_detail_controller.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/warehouse_capacity_widgets.dart';
import 'package:stock_management/View/PurchaseOrders/po_parts.dart';

/// One purchase order: what was ordered, what has arrived, and the action
/// its status allows (submit, approve / reject, receive goods).
class PurchaseOrderDetailScreen extends GetView<PurchaseOrderDetailController> {
  const PurchaseOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Obx(() => PoHeader(title: controller.order.value?.poNumber ?? 'menu_purchase_orders'.tr)),
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
                      if (order.capacity != null && (order.capacity!.isOver || order.capacity!.isNearlyFull)) ...[
                        const SizedBox(height: 12),
                        CapacityBanner(info: order.capacity!, warehouseName: order.warehouseName, onlyWarnings: true),
                      ],
                      if (order.pendingCatalogCount > 0) ...[
                        const SizedBox(height: 12),
                        _pendingCatalog(order),
                      ] else if (controller.hasAddedCatalog && controller.canExport) ...[
                        const SizedBox(height: 12),
                        _addedCatalog(),
                      ],
                      if (order.status == PoStatus.rejected && order.rejectionReason != null) ...[
                        const SizedBox(height: 12),
                        PoErrorBanner('${'po_rejected_reason'.tr}: ${order.rejectionReason}'),
                      ],
                      const SizedBox(height: 20),
                      PoSectionLabel('po_section_products'.tr),
                      const SizedBox(height: 10),
                      for (final item in order.items) ...[
                        _ItemCard(item: item, showProgress: _showProgress(order)),
                        const SizedBox(height: 10),
                      ],
                      if (order.receipts.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        PoSectionLabel('po_section_receipts'.tr),
                        const SizedBox(height: 10),
                        for (final receipt in order.receipts) ...[
                          _ReceiptCard(receipt: receipt),
                          const SizedBox(height: 10),
                        ],
                      ],
                      const SizedBox(height: 14),
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

  bool _showProgress(PurchaseOrderDetail order) =>
      order.status == PoStatus.approved ||
      order.status == PoStatus.partiallyReceived ||
      order.status == PoStatus.received ||
      order.status == PoStatus.closed;

  Widget _summary(PurchaseOrderDetail order) {
    return PoCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatMoney(order.totalAmount),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.brand700),
                ),
              ),
              PoStatusBadge(order.status),
            ],
          ),
          const SizedBox(height: 8),
          PoInfoRow('field_supplier'.tr, order.supplierName),
          PoInfoRow('po_field_receiving_warehouse'.tr, order.warehouseName),
          if (order.createdByName != null) PoInfoRow('po_created_by'.tr, order.createdByName!),
          PoInfoRow('po_created_on'.tr, formatDate(order.createdAt)),
          if (order.approverName != null) PoInfoRow('po_sent_to'.tr, order.approverName!),
          if (order.decidedByName != null) PoInfoRow('po_decided_by'.tr, order.decidedByName!),
          if (order.note != null) PoInfoRow('field_note'.tr, order.note!),
        ],
      ),
    );
  }

  /// New products that arrived but are not in the catalogue (nor stock) yet.
  Widget _pendingCatalog(PurchaseOrderDetail order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(14)),
      child: Obx(() {
        final busy = controller.isBusy.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'po_pending_title'.tr,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.warning),
            ),
            const SizedBox(height: 4),
            Text(
              'po_pending_note'.trParams({'count': '${order.pendingCatalogCount}'}),
              style: TextStyle(fontSize: 12, color: AppColors.warning, height: 1.4),
            ),
            if (controller.canExport) ...[
              const SizedBox(height: 12),
              AppButton(
                label: 'po_action_export_products'.tr,
                icon: Icons.download_rounded,
                onPressed: busy ? null : controller.exportPending,
              ),
            ],
            if (controller.canMarkCatalogAdded) ...[
              const SizedBox(height: 8),
              AppButton(
                label: 'po_action_mark_added'.tr,
                variant: AppButtonVariant.secondary,
                onPressed: busy ? null : controller.markCatalogAdded,
              ),
            ],
          ],
        );
      }),
    );
  }

  /// All new products are marked as added; keep a way to export the file again.
  Widget _addedCatalog() {
    return Obx(() => AppButton(
          label: 'po_action_export_again'.tr,
          icon: Icons.download_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: controller.isBusy.value ? null : controller.exportPending,
        ));
  }

  Widget get _actions {
    return Obx(() {
      final error = controller.errorMessage.value;
      final busy = controller.isBusy.value;
      final children = <Widget>[];
      if (controller.canReceive) {
        children.add(AppButton(label: 'po_action_receive'.tr, icon: Icons.inventory_2_outlined, onPressed: busy ? null : controller.receive));
        children.add(AppButton(label: 'po_action_close'.tr, variant: AppButtonVariant.secondary, onPressed: busy ? null : controller.closeOrder));
      }
      if (controller.canDecide) {
        children.add(AppButton(label: 'action_approve'.tr, isLoading: busy, onPressed: busy ? null : controller.approve));
        children.add(AppButton(label: 'action_reject'.tr, variant: AppButtonVariant.secondary, onPressed: busy ? null : controller.reject));
      }
      if (controller.canEdit) {
        children.add(AppButton(label: 'po_action_submit'.tr, isLoading: busy, onPressed: busy ? null : controller.submit));
        children.add(AppButton(label: 'action_edit'.tr, variant: AppButtonVariant.secondary, onPressed: busy ? null : controller.edit));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) PoErrorBanner(error),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      );
    });
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.showProgress});

  final PurchaseOrderItemData item;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final done = item.remainingQuantity <= 0;
    return PoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  item.displayName,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              if (item.isNew) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.pendingCatalog ? AppColors.warningBg : AppColors.brand100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (item.pendingCatalog
                            ? 'po_badge_pending'
                            : item.catalogAdded
                                ? 'po_badge_added'
                                : 'po_badge_new')
                        .tr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: item.pendingCatalog ? AppColors.warning : AppColors.brand700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (item.isNew)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                [
                  if (item.newCategoryName != null) item.newCategoryName!,
                  if (item.newUnit != null) item.newUnit!,
                  if (item.newSku != null) 'SKU ${item.newSku}',
                ].join(' • '),
                style: TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatQty(item.quantity)} × ${formatMoney(item.unitPrice)}',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
              Text(
                formatMoney(item.lineTotal),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.quantity <= 0 ? 0 : (item.receivedQuantity / item.quantity).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.pageBg,
                color: done ? AppColors.success : AppColors.brand600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'po_received_of'.trParams({'received': formatQty(item.receivedQuantity), 'total': formatQty(item.quantity)}),
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: done ? AppColors.success : AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt});

  final GoodsReceiptData receipt;

  String _issueLabel(String reason) => switch (reason) {
        'DAMAGED' => 'po_issue_damaged'.tr,
        'WRONG_ITEM' => 'po_issue_wrong'.tr,
        _ => 'po_issue_not_arrived'.tr,
      };

  @override
  Widget build(BuildContext context) {
    return PoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  receipt.receiptNumber,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              Text(formatDate(receipt.createdAt), style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
            ],
          ),
          if (receipt.receivedByName != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(receipt.receivedByName!, style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
          if (receipt.rating != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= receipt.rating! ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 16,
                      color: i <= receipt.rating! ? AppColors.warning : AppColors.textTertiary,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          for (final line in receipt.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text(line.name, style: TextStyle(fontSize: 12.5, color: AppColors.ink))),
                  Text('+${formatQty(line.quantity)}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.success)),
                ],
              ),
            ),
          for (final issue in receipt.issues)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${issue.name} • ${_issueLabel(issue.reason)}',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                  Text(
                    '-${formatQty(issue.quantity)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: issue.reason == 'NOT_ARRIVED' ? AppColors.warning : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          if (receipt.note != null) ...[
            const SizedBox(height: 6),
            Text(receipt.note!, style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}
