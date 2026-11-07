import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/stock_controller.dart';
import 'package:stock_management/Controller/stock_line.dart';
import 'package:stock_management/Model/lookup_models.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/View/Components/product_image.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';

/// "Product" field of a stock-movement line: tap to pick one of the existing
/// products from a searchable list (name or SKU) instead of typing a SKU.
class StockProductPicker extends StatelessWidget {
  const StockProductPicker({
    super.key,
    required this.line,
    required this.catalog,
    required this.warehouse,
    required this.onlyInStock,
    required this.onSelected,
  });

  final StockLine line;
  final StockController catalog;

  /// The warehouse the line is in (read when the list opens).
  final LookupOption? Function() warehouse;

  /// True when the list should only offer products that are in stock in
  /// [warehouse] (Stock Out, Transfer, Adjust-decrease).
  final bool Function() onlyInStock;

  /// Called with the product the person picked.
  final ValueChanged<StockItemData> onSelected;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final product = line.product.value;
      return FormField<StockItemData>(
        key: ValueKey('product_${product?.code ?? product?.sku}'),
        initialValue: product,
        validator: (_) => line.product.value == null ? 'validation_select_required'.tr : null,
        builder: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'field_product'.tr,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _open(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: product == null ? 14 : 10),
                  decoration: BoxDecoration(
                    color: AppColors.pageBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: state.hasError ? AppColors.danger : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      if (product != null) ...[
                        ProductImage(url: product.imageUrl, size: 36, radius: 10),
                        const SizedBox(width: 10),
                      ] else ...[
                        Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.textTertiary),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: product == null
                            ? Text(
                                'hint_select_product'.tr,
                                style: TextStyle(fontSize: 13.5, color: AppColors.muted),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                                  ),
                                  Text(
                                    'SKU ${product.sku}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                                  ),
                                ],
                              ),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(state.errorText!, style: TextStyle(fontSize: 11.5, color: AppColors.danger)),
                ),
            ],
          );
        },
      );
    });
  }

  void _open(BuildContext context) {
    final where = warehouse();
    final needStock = onlyInStock();
    if (needStock && where == null) {
      AppSnackbar.warning('field_product'.tr, 'hint_select_warehouse_first'.tr);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _ProductSheet(
        catalog: catalog,
        warehouse: where,
        onlyInStock: needStock,
        selected: line.product.value,
        onPicked: (item) {
          onSelected(item);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

class _ProductSheet extends StatefulWidget {
  const _ProductSheet({
    required this.catalog,
    required this.warehouse,
    required this.onlyInStock,
    required this.selected,
    required this.onPicked,
  });

  final StockController catalog;
  final LookupOption? warehouse;
  final bool onlyInStock;
  final StockItemData? selected;
  final ValueChanged<StockItemData> onPicked;

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  String _query = '';

  List<StockItemData> _filtered(List<StockItemData> all) {
    final q = _query.trim().toLowerCase();
    // Products without a server code can't be sent in a request.
    final usable = all.where((p) {
      if ((p.code ?? '').isEmpty) return false;
      if (widget.onlyInStock && _inWarehouse(p) <= 0) return false;
      return true;
    });
    if (q.isEmpty) return usable.toList();
    return usable.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          (p.barcode ?? '').toLowerCase().contains(q) ||
          p.variants.any((v) => v.sku.toLowerCase().contains(q) || v.variantName.toLowerCase().contains(q));
    }).toList();
  }

  /// On-hand of [p] in the chosen warehouse, or in total when none is chosen.
  int _inWarehouse(StockItemData p) {
    final where = widget.warehouse;
    if (where == null) return p.quantity;
    for (final s in p.warehouseStocks) {
      if (s.warehouseCode == where.code) return s.quantity;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.catalog;
    final selected = widget.selected;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Text(
                  'field_product'.tr,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    hintText: 'search_product_sku'.tr,
                    filled: true,
                    fillColor: AppColors.pageBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Obx(() {
                  final loading = stock.isLoading.value;
                  final items = _filtered(stock.allItems);
                  if (loading && items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (items.isEmpty) {
                    return Center(
                      child: Text('empty_products_found'.tr, style: TextStyle(color: AppColors.muted)),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final isSelected = selected != null && selected.code == item.code;
                      return ListTile(
                        leading: ProductImage(url: item.imageUrl, size: 40, radius: 10),
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        subtitle: Text(
                          'SKU ${item.sku} · ${'label_on_hand_qty'.trParams({'qty': '${_inWarehouse(item)}'})}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.brand600) : null,
                        onTap: () => widget.onPicked(item),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
