import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Model/lookup_models.dart';
import 'package:stock_management/Model/stock_models.dart';

/// One product row of a stock-movement form: the chosen product, its variant
/// (when it has any) and the quantity. A request or a direct save is made of
/// one or more of these.
class StockLine {
  StockLine() {
    quantityController.addListener(() => enteredQty.value = int.tryParse(quantityController.text.trim()));
  }

  /// Stable identity for list keys (a line can move when another is removed).
  final id = UniqueKey();

  final product = Rxn<StockItemData>();

  /// Only used when [product] has variants.
  final variant = Rxn<LookupOption>();

  /// Where this line's stock is (Stock In/Out, Adjust). Transfer uses one
  /// source warehouse for the whole request instead.
  final warehouse = Rxn<LookupOption>();

  /// Adjust only: whether this line raises (true) or lowers (false) the count.
  final increase = true.obs;

  final quantityController = TextEditingController();
  final enteredQty = RxnInt();

  /// Picks (or clears) the product. A product with exactly one variant has
  /// it chosen for you.
  void selectProduct(StockItemData? found) {
    product.value = found;
    variant.value = null;
    if (found == null) return;
    final options = variantOptions;
    if (options.length == 1) variant.value = options.first;
  }

  LookupOption _optionFor(ProductVariantData v) => LookupOption(
        id: v.id ?? v.variantCode,
        code: v.variantCode,
        name: v.sku.isEmpty ? v.variantName : '${v.variantName} (${v.sku})',
      );

  /// Variants of the chosen product, as picker options (empty when none).
  List<LookupOption> get variantOptions {
    final p = product.value;
    if (p == null) return const [];
    return p.variants.map(_optionFor).toList();
  }

  bool get needsVariant => variantOptions.isNotEmpty;

  ProductVariantData? get variantData {
    final p = product.value;
    final picked = variant.value;
    if (p == null || picked == null) return null;
    for (final v in p.variants) {
      if (v.variantCode == picked.code) return v;
    }
    return null;
  }

  /// Stock per warehouse of the chosen variant (or of the whole product while
  /// no variant is chosen). Empty when the product isn't stored anywhere yet.
  List<WarehouseStockData> get stocks {
    final p = product.value;
    if (p == null) return const [];
    return variantData?.warehouseStocks ?? p.warehouseStocks;
  }

  /// On-hand quantity for the chosen variant (or product) — in [where] once
  /// a warehouse is picked, otherwise across all warehouses. Null until it
  /// can be known (no product yet, or a variant still to choose).
  int? onHandIn(LookupOption? where) {
    final p = product.value;
    if (p == null) return null;
    final v = variantData;
    if (needsVariant && v == null) return null;
    final stocks = v?.warehouseStocks ?? p.warehouseStocks;
    if (where != null) {
      for (final s in stocks) {
        if (s.warehouseCode == where.code) return s.quantity;
      }
      return 0;
    }
    return v?.quantity ?? p.quantity;
  }

  /// `Name` or `Name — Variant`, for messages.
  String get displayName {
    final p = product.value;
    if (p == null) return '';
    final v = variant.value;
    return v == null ? p.name : '${p.name} — ${v.name}';
  }

  /// `{productCode, variantCode?}` — the product part of every request row.
  Map<String, dynamic> baseRow() => {
        'productCode': product.value!.code,
        if (variant.value != null) 'variantCode': variant.value!.code,
      };

  void dispose() => quantityController.dispose();
}

enum ImpactTone { neutral, positive, danger }

/// What a line shows under its quantity: two stats (`Current -> After`,
/// `On hand -> Moving`) and an optional warning.
class LineImpact {
  const LineImpact({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    this.tone = ImpactTone.neutral,
    this.warning,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final ImpactTone tone;
  final String? warning;
}
