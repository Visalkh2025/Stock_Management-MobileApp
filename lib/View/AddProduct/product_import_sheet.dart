import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/View/Components/app_button.dart';

/// Review of an Excel file before anything is saved: every product that
/// would be created (with its first stock), or the problems found.
/// Pops `true` when the person confirms the import.
class ProductImportSheet extends StatelessWidget {
  const ProductImportSheet({super.key, required this.fileName, required this.rows, required this.errors});

  final String fileName;
  final List<Map<String, dynamic>> rows;
  final List<String> errors;

  bool get _ok => errors.isEmpty && rows.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Text(
                'import_review_title'.tr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                _ok
                    ? 'import_review_summary'.trParams({'file': fileName, 'count': '${rows.length}'})
                    : 'import_review_errors_title'.trParams({'file': fileName, 'count': '${errors.length}'}),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _ok ? AppColors.success : AppColors.danger,
                ),
              ),
            ),
            Expanded(
              child: errors.isNotEmpty
                  ? ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: errors.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_rounded, size: 18, color: AppColors.danger),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(errors[index], style: const TextStyle(fontSize: 12.5, color: AppColors.danger, height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
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
                    label: 'import_review_confirm'.trParams({'count': '${rows.length}'}),
                    onPressed: _ok ? () => Navigator.of(context).pop(true) : null,
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

  final Map<String, dynamic> row;

  String _text(String key) => (row[key] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (_text('category').isNotEmpty) _text('category'),
      if (_text('unit').isNotEmpty) _text('unit'),
      if (_text('sku').isNotEmpty) 'SKU ${_text('sku')}',
    ].join(' • ');
    final stock = 'import_review_stock'.trParams({'qty': _text('quantity'), 'warehouse': _text('warehouses')});
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _text('name'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.brand100, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        _text('code'),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brand700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(details, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                Text(stock, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
