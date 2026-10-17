import 'package:get/get.dart';

/// Stock status for a single product/SKU row on the Stock screen.
enum StockStatus { inStock, lowStock, outOfStock }

extension StockStatusX on StockStatus {
  // A getter (not a fixed value) so it re-evaluates `.tr` against
  // whichever language is active every time it's read.
  String get label {
    switch (this) {
      case StockStatus.inStock:
        return 'stock_status_in_stock'.tr;
      case StockStatus.lowStock:
        return 'stock_status_low_stock'.tr;
      case StockStatus.outOfStock:
        return 'stock_status_out_of_stock'.tr;
    }
  }
}

/// Which filter chip is active at the top of the Stock screen.
enum StockFilter { all, low, out }

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

String? _imageOf(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

StockStatus _statusFor(int qty, int? minStock) {
  if (qty <= 0) return StockStatus.outOfStock;
  if (minStock != null && minStock > 0 && qty <= minStock) return StockStatus.lowStock;
  return StockStatus.inStock;
}

/// How many of a product/variant sit in one warehouse, and where inside it
/// (free-text [location], e.g. "A-02-3").
class WarehouseStockData {
  const WarehouseStockData({
    required this.warehouseCode,
    required this.warehouseName,
    required this.quantity,
    this.location,
  });

  final String warehouseCode;
  final String warehouseName;
  final int quantity;
  final String? location;

  factory WarehouseStockData.fromJson(Map<String, dynamic> json) {
    final warehouse = json['warehouse'] as Map<String, dynamic>? ?? const {};
    final location = (json['location'] as String?)?.trim();
    return WarehouseStockData(
      warehouseCode: (warehouse['code'] ?? '').toString(),
      warehouseName: (warehouse['name'] ?? '').toString(),
      quantity: _toDouble(json['quantity']).round(),
      location: (location == null || location.isEmpty) ? null : location,
    );
  }
}

String _warehouseSummary(List<WarehouseStockData> stocks) {
  final names = stocks.map((s) => s.warehouseName).where((n) => n.isNotEmpty).toSet();
  if (names.isEmpty) return '';
  if (names.length == 1) return names.first;
  return '${names.length} warehouses';
}

/// One variant row under a product that has [StockItemData.hasVariants] —
/// e.g. "Black / 128GB" under "iPhone 15". Mirrors the `variants[]` +
/// `stock[]` shape from the real product-create request payload: each
/// variant carries its own price and — since a variant can be stocked in a
/// different warehouse than its siblings — its own [warehouse].
class ProductVariantData {
  const ProductVariantData({
    required this.variantCode,
    required this.variantName,
    required this.sku,
    required this.warehouse,
    required this.quantity,
    required this.status,
    this.costPrice,
    this.sellingPrice,
    this.id,
    this.barcode,
    this.warehouseStocks = const [],
    this.imageUrl,
  });

  final String? id;
  final String? barcode;

  /// Photo URL (Cloudinary) or null.
  final String? imageUrl;
  final List<WarehouseStockData> warehouseStocks;

  factory ProductVariantData.fromJson(Map<String, dynamic> json, {int? minStock}) {
    final stocks = (json['stocks'] as List? ?? const [])
        .map((e) => WarehouseStockData.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final qty = stocks.fold<int>(0, (sum, s) => sum + s.quantity);
    return ProductVariantData(
      id: json['id']?.toString(),
      variantCode: (json['code'] ?? '').toString(),
      variantName: (json['name'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      barcode: json['barcode']?.toString(),
      warehouse: _warehouseSummary(stocks),
      quantity: qty,
      status: _statusFor(qty, minStock),
      costPrice: _toDoubleOrNull(json['costPrice']),
      sellingPrice: _toDoubleOrNull(json['sellingPrice']),
      warehouseStocks: stocks,
      imageUrl: _imageOf(json['image']),
    );
  }

  final String variantCode;
  final String variantName;
  final String sku;
  final String warehouse;
  final int quantity;
  final StockStatus status;
  final double? costPrice;
  final double? sellingPrice;
}

/// One product row in the Stock list. A product with [variants] renders as
/// an expandable card on the Stock screen — [quantity]/[status]/[warehouse]
/// then read as the *aggregate* across all variants rather than a
/// standalone figure, and [costPrice]/[sellingPrice] are only meaningful
/// when the product has no variants (pricing lives per-variant otherwise —
/// same rule as the product-create request payload).
class StockItemData {
  const StockItemData({
    required this.name,
    required this.sku,
    required this.warehouse,
    required this.quantity,
    required this.status,
    this.variants = const [],
    this.category,
    this.brand,
    this.unit = 'PCS',
    this.costPrice,
    this.sellingPrice,
    this.supplier,
    this.description,
    this.minStock,
    this.barcode,
    this.id,
    this.code,
    this.warehouseStocks = const [],
    this.matchedVariantCode,
    this.imageUrl,
  });

  /// Product photo URL (Cloudinary) or null when none was uploaded.
  final String? imageUrl;

  /// Server-side identity (null for items that only exist locally).
  final String? id;

  /// Internal product code (PRD-0001), distinct from [sku].
  final String? code;

  /// Stock per warehouse (with the in-warehouse location), summed over
  /// every variant.
  final List<WarehouseStockData> warehouseStocks;

  /// Set by the scanner lookup when the scanned code belonged to a variant.
  final String? matchedVariantCode;

  factory StockItemData.fromJson(Map<String, dynamic> json) {
    final stocks = (json['stocks'] as List? ?? const [])
        .map((e) => WarehouseStockData.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final qty = stocks.fold<int>(0, (sum, s) => sum + s.quantity);
    final minRaw = _toDouble(json['minimumStock']).round();
    final minStock = minRaw > 0 ? minRaw : null;
    final variants = (json['variants'] as List? ?? const [])
        .map((e) => ProductVariantData.fromJson(Map<String, dynamic>.from(e as Map), minStock: minStock))
        .toList();
    final matchedId = json['matchedVariantId']?.toString();
    String? matchedCode;
    if (matchedId != null) {
      for (final v in variants) {
        if (v.id == matchedId) matchedCode = v.variantCode;
      }
    }
    String? nameOf(dynamic obj) => obj is Map ? obj['name']?.toString() : null;
    return StockItemData(
      id: json['id']?.toString(),
      code: json['code']?.toString(),
      name: (json['name'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      warehouse: _warehouseSummary(stocks),
      quantity: qty,
      status: _statusFor(qty, minStock),
      variants: variants,
      category: nameOf(json['category']),
      brand: nameOf(json['brand']),
      unit: (json['unit'] ?? 'PCS').toString(),
      costPrice: _toDoubleOrNull(json['costPrice']),
      sellingPrice: _toDoubleOrNull(json['sellingPrice']),
      supplier: nameOf(json['supplier']),
      description: json['description']?.toString(),
      minStock: minStock,
      barcode: json['barcode']?.toString(),
      warehouseStocks: stocks,
      matchedVariantCode: matchedCode,
      imageUrl: _imageOf(json['image']),
    );
  }

  final String name;
  final String sku;
  final String warehouse;
  final int quantity;
  final StockStatus status;
  final List<ProductVariantData> variants;

  // Optional — mirrors categoryCode/brandCode/unit from the product-create
  // request payload. Null when the demo item doesn't need it in the UI yet.
  final String? category;
  final String? brand;
  final String unit;
  final double? costPrice;
  final double? sellingPrice;

  // Optional extras carried from the Add Product form so the full record
  // (e.g. on the Request Detail screen) isn't limited to the Stock list's
  // original fields.
  final String? supplier;
  final String? description;
  final int? minStock;
  final String? barcode;

  bool get hasVariants => variants.isNotEmpty;
}
