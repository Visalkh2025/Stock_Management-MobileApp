import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/goods_receiving_controller.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_text_field.dart';
import 'package:stock_management/View/PurchaseOrders/po_parts.dart';

/// Goods receiving: type what actually arrived for each line (pre-filled with
/// what is still to come) and confirm once — the stock goes up in the order's
/// warehouse by exactly those quantities.
class GoodsReceivingScreen extends GetView<GoodsReceivingController> {
  const GoodsReceivingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = controller.order;
    return Scaffold(
      body: Column(
        children: [
          PoHeader(title: 'po_receiving_title'.tr),
          Expanded(
            child: SafeArea(
              top: false,
              child: Form(
                key: controller.formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    PoCard(
                      child: Column(
                        children: [
                          PoInfoRow('po_number'.tr, order.poNumber),
                          PoInfoRow('field_supplier'.tr, order.supplierName),
                          PoInfoRow('po_field_receiving_warehouse'.tr, order.warehouseName),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PoSectionLabel('po_section_receive_now'.tr),
                    const SizedBox(height: 4),
                    Text('po_receive_count_hint'.tr, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 10),
                    for (final item in controller.items) ...[
                      _line(item),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 4),
                    _summary,
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'field_note'.tr,
                      controller: controller.noteController,
                      hintText: 'hint_optional'.tr,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    Obx(() {
                      final error = controller.errorMessage.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (error != null) PoErrorBanner(error),
                          AppButton(
                            label: 'po_action_confirm_receipt'.tr,
                            icon: Icons.check_rounded,
                            isLoading: controller.isSaving.value,
                            onPressed: controller.isSaving.value ? null : controller.confirm,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(PurchaseOrderItemData item) {
    return PoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.displayName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
          if (item.isNew)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'po_receive_creates_product'.tr,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.brand700),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'po_ordered_received_remaining'.trParams({
              'ordered': formatQty(item.quantity),
              'received': formatQty(item.receivedQuantity),
              'remaining': formatQty(item.remainingQuantity),
            }),
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'po_field_received_now'.tr,
            controller: controller.fields[item.id],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => controller.validator(item, v),
          ),
          const SizedBox(height: 8),
          _matchBadge(item),
        ],
      ),
    );
  }

  /// Per-line verdict: matches the order, short, over, or not counted yet.
  Widget _matchBadge(PurchaseOrderItemData item) {
    return Obx(() {
      final kind = controller.matchOf(item);
      final gap = formatQty(controller.gapOf(item).abs());
      final (IconData icon, Color color, String text) = switch (kind) {
        ReceiveMatch.uncounted => (Icons.edit_note_rounded, AppColors.textTertiary, 'po_match_uncounted'.tr),
        ReceiveMatch.match => (Icons.check_circle_rounded, AppColors.success, 'po_match_ok'.tr),
        ReceiveMatch.short => (Icons.warning_amber_rounded, AppColors.warning, 'po_match_short'.trParams({'n': gap})),
        ReceiveMatch.over => (Icons.error_rounded, AppColors.danger, 'po_match_over'.trParams({'n': gap})),
      };
      return Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      );
    });
  }

  /// How many lines match / are short / are over.
  Widget get _summary {
    return Obx(() {
      final ok = controller.countOf(ReceiveMatch.match);
      final short = controller.countOf(ReceiveMatch.short);
      final over = controller.countOf(ReceiveMatch.over);
      return PoCard(
        child: Text(
          'po_match_summary'.trParams({'ok': '$ok', 'short': '$short', 'over': '$over', 'total': '${controller.items.length}'}),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: over > 0 ? AppColors.danger : (short > 0 ? AppColors.warning : AppColors.ink),
          ),
        ),
      );
    });
  }
}
