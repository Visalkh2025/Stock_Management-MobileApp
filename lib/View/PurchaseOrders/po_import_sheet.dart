import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/View/Components/app_button.dart';

/// Preview of an imported Excel / CSV file: every row with the product it
/// matched, or the reason it did not. Pops `true` when the person adds the
/// good rows.
class PoImportSheet extends StatelessWidget {
  const PoImportSheet({super.key, required this.preview});

  final PoImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final rows = preview.rows;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Text(
                'po_import_title'.tr,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'po_import_summary'.trParams({'ok': '${preview.validCount}', 'bad': '${preview.errorCount}'}),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: preview.errorCount == 0 ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: rows.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) => _RowTile(row: rows[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                children: [
                  AppButton(
                    label: 'po_import_add'.trParams({'count': '${preview.validCount}'}),
                    onPressed: preview.validCount == 0 ? null : () => Navigator.of(context).pop(true),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'action_cancel'.tr,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row});

  final PoImportRow row;

  @override
  Widget build(BuildContext context) {
    final ok = row.isValid;
    final code = row.productCode ?? '';
    final title = ok
        ? (row.variantName == null ? row.productName ?? code : '${row.productName} • ${row.variantName}')
        : (code.isNotEmpty ? code : (row.productName ?? '—'));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 18,
            color: ok ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    ),
                    if (ok && row.isNew) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.brand100, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          'po_badge_new'.tr,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brand700),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  ok
                      ? '${formatQty(row.quantity ?? 0)} × ${formatMoney(row.unitPrice ?? 0)}${row.isNew && row.categoryName != null ? ' • ${row.categoryName}' : ''}'
                      : 'po_import_row_error'.trParams({'row': '${row.row}', 'error': row.error ?? ''}),
                  style: TextStyle(fontSize: 12, color: ok ? AppColors.muted : AppColors.danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
