import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';

/// Where a purchase order is in its life. Matches the API's status strings.
enum PoStatus {
  draft('DRAFT', 'po_status_draft'),
  submitted('SUBMITTED', 'po_status_submitted'),
  approved('APPROVED', 'po_status_approved'),
  rejected('REJECTED', 'po_status_rejected'),
  partiallyReceived('PARTIALLY_RECEIVED', 'po_status_partial'),
  received('RECEIVED', 'po_status_received'),
  closed('CLOSED', 'po_status_closed');

  const PoStatus(this.apiValue, this.labelKey);

  final String apiValue;
  final String labelKey;

  static PoStatus fromApi(String? value) =>
      PoStatus.values.firstWhere((s) => s.apiValue == value, orElse: () => PoStatus.draft);

  Color get color {
    switch (this) {
      case PoStatus.draft:
      case PoStatus.closed:
        return AppColors.muted;
      case PoStatus.submitted:
      case PoStatus.partiallyReceived:
        return AppColors.warning;
      case PoStatus.approved:
      case PoStatus.received:
        return AppColors.success;
      case PoStatus.rejected:
        return AppColors.danger;
    }
  }

  Color get background {
    switch (this) {
      case PoStatus.draft:
      case PoStatus.closed:
        return AppColors.pageBg;
      case PoStatus.submitted:
      case PoStatus.partiallyReceived:
        return AppColors.warningBg;
      case PoStatus.approved:
      case PoStatus.received:
        return AppColors.successBg;
      case PoStatus.rejected:
        return AppColors.dangerBg;
    }
  }

  /// Goods can be received while the order is approved or partly received.
  bool get canReceive => this == PoStatus.approved || this == PoStatus.partiallyReceived;

  /// The creator can still change it.
  bool get isEditable => this == PoStatus.draft || this == PoStatus.rejected;
}

double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
String? _str(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

/// 12 -> "12", 2.5 -> "2.5".
String formatQty(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();

String formatMoney(double v) => '\$${v.toStringAsFixed(2)}';

String formatDate(DateTime? d) {
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}

/// One row of the purchase-order list.
class PurchaseOrderSummary {
  const PurchaseOrderSummary({
    required this.id,
    required this.poNumber,
    required this.status,
    required this.totalAmount,
    required this.itemCount,
    required this.supplierName,
    required this.warehouseName,
    this.createdByName,
    this.approverName,
    this.createdAt,
    this.pendingCatalogCount = 0,
  });

  /// The Admin / Super Admin the order was sent to (null = approved automatically).
  final String? approverName;

  /// Received new products that are not in the catalogue (nor in stock) yet.
  final int pendingCatalogCount;

  final String id;
  final String poNumber;
  final PoStatus status;
  final double totalAmount;
  final int itemCount;
  final String supplierName;
  final String warehouseName;
  final String? createdByName;
  final DateTime? createdAt;

  factory PurchaseOrderSummary.fromJson(Map<String, dynamic> json) => PurchaseOrderSummary(
        id: (json['id'] ?? '').toString(),
        poNumber: (json['poNumber'] ?? '').toString(),
        status: PoStatus.fromApi(json['status']?.toString()),
        totalAmount: _num(json['totalAmount']),
        itemCount: _num(json['itemCount']).round(),
        pendingCatalogCount: _num(json['pendingCatalogCount']).round(),
        supplierName: ((json['supplier'] as Map?)?['name'] ?? '').toString(),
        warehouseName: ((json['warehouse'] as Map?)?['name'] ?? '').toString(),
        createdByName: _str((json['createdBy'] as Map?)?['name']),
        approverName: _str((json['approver'] as Map?)?['name']),
        createdAt: _date(json['createdAt']),
      );
}

class PurchaseOrderItemData {
  const PurchaseOrderItemData({
    required this.id,
    this.productCode,
    required this.productName,
    required this.quantity,
    required this.receivedQuantity,
    required this.remainingQuantity,
    required this.unitPrice,
    required this.lineTotal,
    this.isNew = false,
    this.pendingCatalog = false,
    this.catalogAdded = false,
    this.newCategoryCode,
    this.newCategoryName,
    this.newBrandCode,
    this.newBrandName,
    this.newUnit,
    this.newSku,
    this.variantCode,
    this.variantName,
    this.imageUrl,
  });

  final String id;

  /// Null for a "new product" line: the product is created when it is received.
  final String? productCode;
  final String productName;

  /// Set only while the line is a new product that has not been created yet.
  final bool isNew;

  /// Received, but the product is not in the catalogue yet (so not in stock).
  final bool pendingCatalog;

  /// The manager added this new product to the catalogue.
  final bool catalogAdded;
  final String? newCategoryCode;
  final String? newCategoryName;
  final String? newBrandCode;
  final String? newBrandName;
  final String? newUnit;
  final String? newSku;
  final String? variantCode;
  final String? variantName;
  final String? imageUrl;
  final double quantity;
  final double receivedQuantity;
  final double remainingQuantity;
  final double unitPrice;
  final double lineTotal;

  String get displayName => variantName == null ? productName : '$productName • $variantName';

  factory PurchaseOrderItemData.fromJson(Map<String, dynamic> json) {
    final np = json['newProduct'] is Map ? Map<String, dynamic>.from(json['newProduct'] as Map) : null;
    return PurchaseOrderItemData(
        id: (json['id'] ?? '').toString(),
        productCode: _str(json['productCode']),
        isNew: json['isNew'] == true,
        pendingCatalog: json['pendingCatalog'] == true,
        catalogAdded: json['catalogAdded'] == true,
        newCategoryCode: _str(np?['categoryCode']),
        newCategoryName: _str(np?['categoryName']),
        newBrandCode: _str(np?['brandCode']),
        newBrandName: _str(np?['brandName']),
        newUnit: _str(np?['unit']),
        newSku: _str(np?['sku']),
        productName: (json['productName'] ?? '').toString(),
        variantCode: _str(json['variantCode']),
        variantName: _str(json['variantName']),
        imageUrl: _str(json['image']),
        quantity: _num(json['quantity']),
        receivedQuantity: _num(json['receivedQuantity']),
        remainingQuantity: _num(json['remainingQuantity']),
        unitPrice: _num(json['unitPrice']),
        lineTotal: _num(json['lineTotal']),
      );
  }
}

class GoodsReceiptData {
  const GoodsReceiptData({
    required this.id,
    required this.receiptNumber,
    required this.lines,
    this.issues = const [],
    this.rating,
    this.receivedByName,
    this.note,
    this.createdAt,
  });

  final String id;
  final String receiptNumber;
  final String? receivedByName;
  final String? note;
  final DateTime? createdAt;

  /// How the delivery went, 1-5 (null = not rated).
  final int? rating;

  /// "Product name" -> quantity that arrived in this delivery.
  final List<({String name, double quantity})> lines;

  /// What was short in this delivery: name, reason (NOT_ARRIVED / DAMAGED /
  /// WRONG_ITEM) and quantity.
  final List<({String name, String reason, double quantity})> issues;

  factory GoodsReceiptData.fromJson(Map<String, dynamic> json) => GoodsReceiptData(
        id: (json['id'] ?? '').toString(),
        receiptNumber: (json['receiptNumber'] ?? '').toString(),
        receivedByName: _str((json['receivedBy'] as Map?)?['name']),
        note: _str(json['note']),
        rating: json['rating'] == null ? null : _num(json['rating']).round(),
        createdAt: _date(json['createdAt']),
        lines: (json['items'] as List? ?? const []).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final variant = _str(m['variantName']);
          final name = (m['productName'] ?? '').toString();
          return (name: variant == null ? name : '$name • $variant', quantity: _num(m['quantity']));
        }).toList(),
        issues: (json['issues'] as List? ?? const []).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final variant = _str(m['variantName']);
          final name = (m['productName'] ?? '').toString();
          return (
            name: variant == null ? name : '$name • $variant',
            reason: (m['reason'] ?? '').toString(),
            quantity: _num(m['quantity']),
          );
        }).toList(),
      );
}

/// How full a warehouse gets if a purchase order goes through
/// (`capacityInfo` on an order, and `GET /purchase-orders/warehouse-check`).
class WarehouseCapacity {
  const WarehouseCapacity({
    required this.used,
    required this.incoming,
    required this.orderQuantity,
    required this.projected,
    required this.level,
    this.capacity,
    this.freeAfter,
    this.percentAfter,
  });

  /// Null = the warehouse has no limit.
  final double? capacity;
  final double used;
  final double incoming;
  final double orderQuantity;
  final double projected;
  final double? freeAfter;
  final double? percentAfter;

  /// 'unlimited' | 'ok' | 'nearly_full' | 'over'
  final String level;

  bool get hasLimit => capacity != null;
  bool get isOver => level == 'over';
  bool get isNearlyFull => level == 'nearly_full';

  static double? _orNull(dynamic v) => v == null ? null : _num(v);

  factory WarehouseCapacity.fromJson(Map<String, dynamic> json) => WarehouseCapacity(
        capacity: _orNull(json['capacity']),
        used: _num(json['used']),
        incoming: _num(json['incoming']),
        orderQuantity: _num(json['orderQuantity']),
        projected: _num(json['projected']),
        freeAfter: _orNull(json['freeAfter']),
        percentAfter: _orNull(json['percentAfter']),
        level: (json['level'] ?? 'unlimited').toString(),
      );
}

/// What was really bought from one supplier for one product
/// (`GET /purchase-orders/supplier-products/:code`).
class SupplierPurchase {
  const SupplierPurchase({required this.productId, required this.orders, required this.lastPrice});

  final String productId;
  final int orders;
  final double lastPrice;

  factory SupplierPurchase.fromJson(Map<String, dynamic> json) => SupplierPurchase(
        productId: (json['productId'] ?? '').toString(),
        orders: _num(json['orders']).round(),
        lastPrice: _num(json['lastPrice']),
      );
}

class PurchaseOrderDetail {
  const PurchaseOrderDetail({
    required this.id,
    required this.poNumber,
    required this.status,
    required this.totalAmount,
    required this.supplierCode,
    required this.supplierName,
    required this.warehouseCode,
    required this.warehouseName,
    required this.items,
    required this.receipts,
    this.note,
    this.rejectionReason,
    this.createdByName,
    this.decidedByName,
    this.approverId,
    this.approverName,
    this.createdAt,
    this.decidedAt,
    this.pendingCatalogCount = 0,
    this.capacity,
  });

  /// How full the warehouse gets with this order (null once it is received).
  final WarehouseCapacity? capacity;

  /// Who the order was sent to for approval (null = approved automatically).
  final String? approverId;
  final String? approverName;

  /// Received new products still waiting to be added to the catalogue.
  final int pendingCatalogCount;

  final String id;
  final String poNumber;
  final PoStatus status;
  final double totalAmount;
  final String supplierCode;
  final String supplierName;
  final String warehouseCode;
  final String warehouseName;
  final String? note;
  final String? rejectionReason;
  final String? createdByName;
  final String? decidedByName;
  final DateTime? createdAt;
  final DateTime? decidedAt;
  final List<PurchaseOrderItemData> items;
  final List<GoodsReceiptData> receipts;

  double get totalQuantity => items.fold(0, (s, i) => s + i.quantity);
  double get receivedQuantity => items.fold(0, (s, i) => s + i.receivedQuantity);

  factory PurchaseOrderDetail.fromJson(Map<String, dynamic> json) {
    final supplier = Map<String, dynamic>.from(json['supplier'] as Map? ?? const {});
    final warehouse = Map<String, dynamic>.from(json['warehouse'] as Map? ?? const {});
    return PurchaseOrderDetail(
      id: (json['id'] ?? '').toString(),
      poNumber: (json['poNumber'] ?? '').toString(),
      status: PoStatus.fromApi(json['status']?.toString()),
      totalAmount: _num(json['totalAmount']),
      supplierCode: (supplier['code'] ?? '').toString(),
      supplierName: (supplier['name'] ?? '').toString(),
      warehouseCode: (warehouse['code'] ?? '').toString(),
      warehouseName: (warehouse['name'] ?? '').toString(),
      note: _str(json['note']),
      rejectionReason: _str(json['rejectionReason']),
      createdByName: _str((json['createdBy'] as Map?)?['name']),
      decidedByName: _str((json['decidedBy'] as Map?)?['name']),
      approverId: _str((json['approver'] as Map?)?['id']),
      approverName: _str((json['approver'] as Map?)?['name']),
      createdAt: _date(json['createdAt']),
      decidedAt: _date(json['decidedAt']),
      pendingCatalogCount: _num(json['pendingCatalogCount']).round(),
      capacity: json['capacityInfo'] is Map
          ? WarehouseCapacity.fromJson(Map<String, dynamic>.from(json['capacityInfo'] as Map))
          : null,
      items: (json['items'] as List? ?? const [])
          .map((e) => PurchaseOrderItemData.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      receipts: (json['receipts'] as List? ?? const [])
          .map((e) => GoodsReceiptData.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// One row of an imported Excel / CSV file, checked by the server.
/// [error] is null when the row is good.
class PoImportRow {
  const PoImportRow({
    required this.row,
    this.productCode,
    this.variantCode,
    this.productName,
    this.variantName,
    this.isNew = false,
    this.categoryCode,
    this.categoryName,
    this.unit,
    this.sku,
    this.quantity,
    this.unitPrice,
    this.error,
  });

  final int row;

  /// Null for a new product (it does not exist yet).
  final String? productCode;
  final String? variantCode;
  final String? productName;
  final String? variantName;
  final bool isNew;
  final String? categoryCode;
  final String? categoryName;
  final String? unit;
  final String? sku;
  final double? quantity;
  final double? unitPrice;
  final String? error;

  bool get isValid => error == null;

  factory PoImportRow.fromJson(Map<String, dynamic> json) => PoImportRow(
        row: _num(json['row']).round(),
        productCode: _str(json['productCode']),
        variantCode: _str(json['variantCode']),
        productName: _str(json['productName']),
        variantName: _str(json['variantName']),
        isNew: json['isNew'] == true,
        categoryCode: _str(json['categoryCode']),
        categoryName: _str(json['categoryName']),
        unit: _str(json['unit']),
        sku: _str(json['sku']),
        quantity: json['quantity'] == null ? null : _num(json['quantity']),
        unitPrice: json['unitPrice'] == null ? null : _num(json['unitPrice']),
        error: _str(json['error']),
      );
}

class PoImportPreview {
  const PoImportPreview({required this.rows});

  final List<PoImportRow> rows;

  List<PoImportRow> get validRows => rows.where((r) => r.isValid).toList();
  int get validCount => rows.where((r) => r.isValid).length;
  int get errorCount => rows.length - validCount;

  factory PoImportPreview.fromJson(Map<String, dynamic> json) => PoImportPreview(
        rows: (json['rows'] as List? ?? const [])
            .map((e) => PoImportRow.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// An Admin / Super Admin a Manager can send a purchase order to.
class PoApprover {
  const PoApprover({required this.id, required this.name, this.roles = const []});

  final String id;
  final String name;
  final List<String> roles;

  String get label => roles.isEmpty ? name : '$name • ${roles.join(', ')}';

  factory PoApprover.fromJson(Map<String, dynamic> json) => PoApprover(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        roles: (json['roles'] as List? ?? const []).map((e) => e.toString()).toList(),
      );
}

/// A product at or below its minimum stock (`GET /purchase-orders/reorder`).
class ReorderItem {
  const ReorderItem({
    required this.productId,
    required this.code,
    required this.name,
    required this.unit,
    required this.hasVariants,
    required this.stock,
    required this.minimumStock,
    required this.isOut,
    required this.onOrder,
    required this.onOrderPoNumbers,
    required this.suggestedQuantity,
    required this.covered,
    this.image,
    this.maximumStock,
  });

  final String productId;
  final String code;
  final String name;
  final String unit;
  final String? image;
  final bool hasVariants;
  final double stock;
  final double minimumStock;
  final double? maximumStock;

  /// Stock is 0 (otherwise it is only low).
  final bool isOut;

  /// Quantity already ordered in open purchase orders and not received yet.
  final double onOrder;
  final List<String> onOrderPoNumbers;
  final int suggestedQuantity;

  /// What is already on order is enough to refill it.
  final bool covered;

  factory ReorderItem.fromJson(Map<String, dynamic> json) => ReorderItem(
        productId: (json['productId'] ?? '').toString(),
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        unit: (json['unit'] ?? 'PCS').toString(),
        image: _str(json['image']),
        hasVariants: json['hasVariants'] == true,
        stock: _num(json['stock']),
        minimumStock: _num(json['minimumStock']),
        maximumStock: json['maximumStock'] == null ? null : _num(json['maximumStock']),
        isOut: json['status'] == 'OUT',
        onOrder: _num(json['onOrder']),
        onOrderPoNumbers: (json['onOrderPoNumbers'] as List? ?? const []).map((e) => e.toString()).toList(),
        suggestedQuantity: _num(json['suggestedQuantity']).round(),
        covered: json['covered'] == true,
      );
}

class ReorderSummary {
  const ReorderSummary({required this.total, required this.outCount, required this.lowCount, required this.items});

  final int total;
  final int outCount;
  final int lowCount;
  final List<ReorderItem> items;

  factory ReorderSummary.fromJson(Map<String, dynamic> json) => ReorderSummary(
        total: _num(json['total']).round(),
        outCount: _num(json['outCount']).round(),
        lowCount: _num(json['lowCount']).round(),
        items: (json['items'] as List? ?? const [])
            .map((e) => ReorderItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// One supplier a product was bought from, with how the purchases went.
class SupplierOffer {
  const SupplierOffer({
    required this.code,
    required this.name,
    required this.isDefault,
    required this.timesOrdered,
    required this.totalQuantity,
    required this.lastPrice,
    required this.lowestPrice,
    required this.averagePrice,
    this.damagedQuantity = 0,
    this.wrongQuantity = 0,
    this.fillRate,
    this.averageRating,
    this.ratingCount = 0,
    this.lastOrderedAt,
    this.averageLeadDays,
  });

  final String code;
  final String name;

  /// The product's usual supplier (set on the product).
  final bool isDefault;
  final int timesOrdered;
  final double totalQuantity;
  final double lastPrice;
  final double lowestPrice;
  final double averagePrice;

  /// Units that arrived broken / not as ordered.
  final double damagedQuantity;
  final double wrongQuantity;

  /// % of the ordered quantity that arrived, over finished orders (null = none finished).
  final double? fillRate;

  /// Average delivery rating 1-5 (null = never rated).
  final double? averageRating;
  final int ratingCount;
  final DateTime? lastOrderedAt;

  /// Days from approval to the first delivery, averaged (null = never delivered).
  final double? averageLeadDays;

  bool get hasHistory => timesOrdered > 0;

  /// Broken + wrong units (0 = none reported).
  double get problemQuantity => damagedQuantity + wrongQuantity;

  /// Dependable: delivers (almost) everything, rated 4+ and no damaged / wrong units.
  bool get isReliable =>
      hasHistory &&
      fillRate != null &&
      fillRate! >= 95 &&
      averageRating != null &&
      averageRating! >= 4 &&
      problemQuantity == 0;

  factory SupplierOffer.fromJson(Map<String, dynamic> json) => SupplierOffer(
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        isDefault: json['isDefault'] == true,
        timesOrdered: _num(json['timesOrdered']).round(),
        totalQuantity: _num(json['totalQuantity']),
        lastPrice: _num(json['lastPrice']),
        lowestPrice: _num(json['lowestPrice']),
        averagePrice: _num(json['averagePrice']),
        damagedQuantity: _num(json['damagedQuantity']),
        wrongQuantity: _num(json['wrongQuantity']),
        fillRate: json['fillRate'] == null ? null : _num(json['fillRate']),
        averageRating: json['averageRating'] == null ? null : _num(json['averageRating']),
        ratingCount: _num(json['ratingCount']).round(),
        lastOrderedAt: _date(json['lastOrderedAt']),
        averageLeadDays: json['averageLeadDays'] == null ? null : _num(json['averageLeadDays']),
      );
}

class SupplierHistory {
  const SupplierHistory({required this.suppliers});

  final List<SupplierOffer> suppliers;

  factory SupplierHistory.fromJson(Map<String, dynamic> json) => SupplierHistory(
        suppliers: (json['suppliers'] as List? ?? const [])
            .map((e) => SupplierOffer.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// What the new-order form starts with when it is opened from the reorder
/// flow (instead of an existing order to edit).
class PoPrefill {
  const PoPrefill({required this.lines, this.supplierCode});

  final String? supplierCode;
  final List<PoPrefillLine> lines;
}

class PoPrefillLine {
  const PoPrefillLine({required this.productCode, required this.quantity, this.price});

  final String productCode;
  final int quantity;
  final double? price;
}
