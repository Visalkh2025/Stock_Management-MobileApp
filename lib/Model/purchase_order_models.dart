import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';

/// Where a purchase order is in its life. Matches the API's status strings.
enum PoStatus {
  draft('DRAFT', 'po_status_draft'),
  submitted('SUBMITTED', 'po_status_submitted'),
  approved('APPROVED', 'po_status_approved'),
  rejected('REJECTED', 'po_status_rejected'),
  partiallyReceived('PARTIALLY_RECEIVED', 'po_status_partial'),
  received('RECEIVED', 'po_status_received');

  const PoStatus(this.apiValue, this.labelKey);

  final String apiValue;
  final String labelKey;

  static PoStatus fromApi(String? value) =>
      PoStatus.values.firstWhere((s) => s.apiValue == value, orElse: () => PoStatus.draft);

  Color get color {
    switch (this) {
      case PoStatus.draft:
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
    this.receivedByName,
    this.note,
    this.createdAt,
  });

  final String id;
  final String receiptNumber;
  final String? receivedByName;
  final String? note;
  final DateTime? createdAt;

  /// "Product name" -> quantity that arrived in this delivery.
  final List<({String name, double quantity})> lines;

  factory GoodsReceiptData.fromJson(Map<String, dynamic> json) => GoodsReceiptData(
        id: (json['id'] ?? '').toString(),
        receiptNumber: (json['receiptNumber'] ?? '').toString(),
        receivedByName: _str((json['receivedBy'] as Map?)?['name']),
        note: _str(json['note']),
        createdAt: _date(json['createdAt']),
        lines: (json['items'] as List? ?? const []).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final variant = _str(m['variantName']);
          final name = (m['productName'] ?? '').toString();
          return (name: variant == null ? name : '$name • $variant', quantity: _num(m['quantity']));
        }).toList(),
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
  });

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
