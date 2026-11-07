import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/purchase_order_service.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/PurchaseOrders/reorder_parts.dart';

/// Bottom sheet inside the new-order form: tick the low / out-of-stock
/// products to add to the order. Pops the picked [ReorderItem]s (null when
/// dismissed). Products already in the order ([excludeCodes]) are not listed.
class PoReorderPicker extends StatefulWidget {
  const PoReorderPicker({super.key, required this.excludeCodes});

  final Set<String> excludeCodes;

  @override
  State<PoReorderPicker> createState() => _PoReorderPickerState();
}

class _PoReorderPickerState extends State<PoReorderPicker> {
  late final Future<ReorderSummary> _future = PurchaseOrderService().fetchReorder();
  final _picked = <String>{};
  final _histories = <String, Future<SupplierHistory>>{};

  Future<SupplierHistory> _historyOf(String productId) =>
      _histories.putIfAbsent(productId, () => PurchaseOrderService().fetchSupplierHistory(productId));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: FutureBuilder<ReorderSummary>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error is ApiException ? error.message : error.toString()),
              );
            }
            final items = (snapshot.data?.items ?? const <ReorderItem>[])
                .where((i) => !widget.excludeCodes.contains(i.code))
                .toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Text(
                    'po_low_stock_pick_title'.tr,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Text(
                      'po_low_stock_none'.tr,
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  )
                else ...[
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final checked = _picked.contains(item.code);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (v) => setState(() => v == true ? _picked.add(item.code) : _picked.remove(item.code)),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.brand700,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ReorderStatusBadge(isOut: item.isOut),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ReorderFacts(item),
                                _SupplierInfo(future: _historyOf(item.productId)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: AppButton(
                      label: 'po_low_stock_add'.trParams({'count': '${_picked.length}'}),
                      onPressed: _picked.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(items.where((i) => _picked.contains(i.code)).toList()),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Under a low-stock product: its usual supplier, and (tap to open) who it
/// was bought from before with price, times, delivery time and tags.
class _SupplierInfo extends StatefulWidget {
  const _SupplierInfo({required this.future});

  final Future<SupplierHistory> future;

  @override
  State<_SupplierInfo> createState() => _SupplierInfoState();
}

class _SupplierInfoState extends State<_SupplierInfo> {
  bool _open = false;

  /// The one supplier that stands out on [value], or null (tie / nobody to compare).
  String? _standout(List<SupplierOffer> list, double? Function(SupplierOffer) value, {required bool lowest}) {
    final c = list.where((o) => value(o) != null).toList();
    if (c.length < 2) return null;
    final best = c.map((o) => value(o)!).reduce((a, b) => (lowest ? b < a : b > a) ? b : a);
    final same = c.where((o) => value(o) == best).toList();
    return same.length == 1 ? same.first.code : null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SupplierHistory>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.only(top: 6),
            child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) return const SizedBox.shrink();
        final offers = snapshot.data?.suppliers ?? const <SupplierOffer>[];
        SupplierOffer? usual;
        for (final o in offers) {
          if (o.isDefault) usual = o;
        }
        final past = offers.where((o) => o.hasHistory).toList();
        final best = _standout(past, (o) => o.lastPrice, lowest: true);
        final fastest = _standout(past, (o) => o.averageLeadDays, lowest: true);
        final most = _standout(past, (o) => o.timesOrdered.toDouble(), lowest: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'po_low_stock_supplier'.trParams({'name': usual?.name ?? 'po_low_stock_supplier_none'.tr}),
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
            if (past.isEmpty)
              Text(
                'po_supplier_history_none'.tr,
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              )
            else ...[
              InkWell(
                onTap: () => setState(() => _open = !_open),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 14, color: AppColors.brand700),
                      const SizedBox(width: 4),
                      Text(
                        'po_low_stock_history'.tr,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.brand700),
                      ),
                      Icon(
                        _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 16,
                        color: AppColors.brand700,
                      ),
                    ],
                  ),
                ),
              ),
              if (_open)
                for (final o in past)
                  _offerRow(o, [
                    if (o.isReliable) ('po_tag_reliable'.tr, AppColors.success, AppColors.successBg),
                    if (o.code == best) ('po_tag_best_price'.tr, AppColors.success, AppColors.successBg),
                    if (o.code == fastest) ('po_tag_fastest'.tr, AppColors.brand700, AppColors.brand50),
                    if (o.code == most) ('po_tag_most_ordered'.tr, AppColors.brand700, AppColors.brand50),
                    if (o.isDefault) ('po_tag_usual'.tr, AppColors.muted, AppColors.pageBg),
                  ]),
            ],
          ],
        );
      },
    );
  }

  Widget _offerRow(SupplierOffer o, List<(String, Color, Color)> tags) {
    final facts = [
      '${'po_supplier_last_price'.tr} ${formatMoney(o.lastPrice)}',
      (o.timesOrdered == 1 ? 'po_supplier_orders_one' : 'po_supplier_orders_value')
          .trParams({'n': '${o.timesOrdered}', 'qty': formatQty(o.totalQuantity)}),
      if (o.averageLeadDays != null)
        '${'po_supplier_lead'.tr} ${'po_supplier_lead_value'.trParams({'d': formatQty(o.averageLeadDays!)})}',
      if (o.lastOrderedAt != null) '${'po_supplier_last_ordered'.tr} ${formatDate(o.lastOrderedAt)}',
      if (o.fillRate != null) 'po_supplier_fill'.trParams({'p': formatQty(o.fillRate!)}),
      if (o.averageRating != null)
        'po_supplier_rating'.trParams({'r': o.averageRating!.toStringAsFixed(1), 'n': '${o.ratingCount}'}),
      if (o.problemQuantity > 0)
        'po_supplier_problems'.trParams({
          'damaged': formatQty(o.damagedQuantity),
          'wrong': formatQty(o.wrongQuantity),
        }),
    ];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(o.name, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final t in tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: t.$3, borderRadius: BorderRadius.circular(20)),
                    child: Text(t.$1, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t.$2)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          for (final f in facts) Text(f, style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }
}
