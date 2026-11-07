import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/supplier_compare_controller.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_text_field.dart';
import 'package:stock_management/View/PurchaseOrders/po_parts.dart';
import 'package:stock_management/View/PurchaseOrders/reorder_parts.dart';

/// Purchase Orders > Needs reorder > product — who this product was bought
/// from (price, how often, delivery time) so the manager can pick a supplier
/// and start the order. See [SupplierCompareController].
class SupplierCompareScreen extends GetView<SupplierCompareController> {
  const SupplierCompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final item = controller.item;
    return Scaffold(
      body: Column(
        children: [
          PoHeader(title: 'po_supplier_title'.tr),
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                final error = controller.errorMessage.value;
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      _productCard(item),
                      const SizedBox(height: 14),
                      PoCard(
                        child: AppTextField(
                          label: 'po_supplier_qty'.tr,
                          controller: controller.quantityController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (error != null) PoErrorBanner(error),
                      PoSectionLabel('po_supplier_section'.tr),
                      const SizedBox(height: 10),
                      ..._suppliers,
                      const SizedBox(height: 4),
                      AppButton(
                        label: 'po_supplier_create_any'.tr,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => controller.createOrder(null),
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

  Widget _productCard(ReorderItem item) {
    return PoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderThumb(item.image),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ReorderStatusBadge(isOut: item.isOut),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.code, style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
                const SizedBox(height: 6),
                ReorderFacts(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> get _suppliers {
    if (controller.isLoading.value && controller.history.value == null) {
      return const [Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))];
    }
    final offers = controller.offers;
    if (offers.isEmpty) {
      return [
        PoCard(
          child: Text(
            'po_supplier_history_empty'.tr,
            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 10),
      ];
    }
    final best = controller.bestPriceCode;
    final fastest = controller.fastestCode;
    final most = controller.mostOrderedCode;
    return [
      for (final offer in offers) ...[
        _SupplierCard(
          offer: offer,
          tags: [
            if (offer.isReliable) ('po_tag_reliable'.tr, AppColors.success, AppColors.successBg),
            if (offer.code == best) ('po_tag_best_price'.tr, AppColors.success, AppColors.successBg),
            if (offer.code == fastest) ('po_tag_fastest'.tr, AppColors.brand700, AppColors.brand50),
            if (offer.code == most) ('po_tag_most_ordered'.tr, AppColors.brand700, AppColors.brand50),
            if (offer.isDefault) ('po_tag_usual'.tr, AppColors.muted, AppColors.pageBg),
          ],
          onCreate: () => controller.createOrder(offer),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({required this.offer, required this.tags, required this.onCreate});

  final SupplierOffer offer;

  /// (label, text color, background)
  final List<(String, Color, Color)> tags;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return PoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            offer.name,
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: tag.$3, borderRadius: BorderRadius.circular(20)),
                    child: Text(tag.$1, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: tag.$2)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          PoInfoRow('po_supplier_last_price'.tr, formatMoney(offer.lastPrice)),
          if (offer.hasHistory) ...[
            PoInfoRow(
              'po_supplier_price_range'.tr,
              '${formatMoney(offer.lowestPrice)} / ${formatMoney(offer.averagePrice)}',
            ),
            PoInfoRow(
              'po_supplier_orders'.tr,
              (offer.timesOrdered == 1 ? 'po_supplier_orders_one' : 'po_supplier_orders_value').trParams({
                'n': '${offer.timesOrdered}',
                'qty': formatQty(offer.totalQuantity),
              }),
            ),
            if (offer.averageLeadDays != null)
              PoInfoRow(
                'po_supplier_lead'.tr,
                'po_supplier_lead_value'.trParams({'d': formatQty(offer.averageLeadDays!)}),
              ),
            if (offer.lastOrderedAt != null) PoInfoRow('po_supplier_last_ordered'.tr, formatDate(offer.lastOrderedAt)),
            if (offer.fillRate != null)
              PoInfoRow('po_supplier_fill_label'.tr, '${formatQty(offer.fillRate!)}%'),
            if (offer.averageRating != null)
              PoInfoRow(
                'po_supplier_rating_label'.tr,
                'po_supplier_rating_value'.trParams({
                  'r': offer.averageRating!.toStringAsFixed(1),
                  'n': '${offer.ratingCount}',
                }),
              ),
            if (offer.problemQuantity > 0)
              PoInfoRow(
                'po_supplier_problems_label'.tr,
                'po_supplier_problems_value'.trParams({
                  'damaged': formatQty(offer.damagedQuantity),
                  'wrong': formatQty(offer.wrongQuantity),
                }),
              ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                'po_supplier_no_history'.tr,
                style: TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
            ),
          const SizedBox(height: 10),
          AppButton(label: 'po_supplier_create'.tr, onPressed: onCreate),
        ],
      ),
    );
  }
}
