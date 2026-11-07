import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/purchase_order_models.dart';

/// Why a line was short, and what to do with the rest of the order.
class PoShortResult {
  const PoShortResult({required this.reasons, required this.close});

  /// Order line id -> NOT_ARRIVED / DAMAGED / WRONG_ITEM.
  final Map<String, String> reasons;

  /// Close the order: the rest is not coming.
  final bool close;
}

/// Shown when goods arrive short. Pops a [PoShortResult], or null to go back
/// and fix the count.
class PoShortDialog extends StatefulWidget {
  const PoShortDialog({super.key, required this.lines});

  /// The short lines and how many are missing on each.
  final List<({PurchaseOrderItemData item, double gap})> lines;

  @override
  State<PoShortDialog> createState() => _PoShortDialogState();
}

class _PoShortDialogState extends State<PoShortDialog> {
  late final Map<String, String> _reasons = {for (final l in widget.lines) l.item.id: 'NOT_ARRIVED'};
  bool _close = false;

  static const _options = [
    ('NOT_ARRIVED', 'po_issue_not_arrived'),
    ('DAMAGED', 'po_issue_damaged'),
    ('WRONG_ITEM', 'po_issue_wrong'),
  ];

  Widget _chip({required String label, required bool selected, required VoidCallback onTap}) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? AppColors.brand700 : AppColors.muted)),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.brand50,
      backgroundColor: AppColors.cardBg,
      side: BorderSide(color: selected ? AppColors.brand700 : AppColors.border),
      onSelected: (_) => onTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('po_short_title'.trParams({'n': '${widget.lines.length}'})),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final l in widget.lines) ...[
              Text(l.item.displayName, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(
                'po_match_short'.trParams({'n': formatQty(l.gap)}),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final o in _options)
                    _chip(
                      label: o.$2.tr,
                      selected: _reasons[l.item.id] == o.$1,
                      onTap: () => setState(() => _reasons[l.item.id] = o.$1),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            Text('po_short_rest'.tr, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chip(label: 'po_short_wait'.tr, selected: !_close, onTap: () => setState(() => _close = false)),
                _chip(label: 'po_short_close'.tr, selected: _close, onTap: () => setState(() => _close = true)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              (_close ? 'po_short_close_hint' : 'po_short_wait_hint').tr,
              style: TextStyle(fontSize: 11.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('po_short_back'.tr)),
        TextButton(
          onPressed: () => Navigator.of(context).pop(PoShortResult(reasons: Map.of(_reasons), close: _close)),
          child: Text('po_short_confirm'.tr),
        ),
      ],
    );
  }
}
