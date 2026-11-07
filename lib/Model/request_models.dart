import 'package:get/get.dart';
import 'package:stock_management/Model/stock_models.dart';

/// Approval status for a single request row on the Requests screen.
enum RequestStatus { pending, approved, rejected }

extension RequestStatusX on RequestStatus {
  // A getter (not a fixed value) so it re-evaluates `.tr` against
  // whichever language is active every time it's read.
  String get label {
    switch (this) {
      case RequestStatus.pending:
        return 'status_pending'.tr;
      case RequestStatus.approved:
        return 'status_approved'.tr;
      case RequestStatus.rejected:
        return 'status_rejected'.tr;
    }
  }
}

/// Where one person stands in a request's approval chain. [waiting] means an
/// earlier step has not finished yet; [pending] means it is their turn.
enum ApproverStatus { waiting, pending, approved, rejected }

extension ApproverStatusX on ApproverStatus {
  String get label {
    switch (this) {
      case ApproverStatus.waiting:
        return 'approver_status_waiting'.tr;
      case ApproverStatus.pending:
        return 'status_pending'.tr;
      case ApproverStatus.approved:
        return 'status_approved'.tr;
      case ApproverStatus.rejected:
        return 'status_rejected'.tr;
    }
  }
}

/// CERTIFIER verifies (e.g. a warehouse verifier); APPROVER gives the final
/// sign-off and must be an ADMIN / MANAGER / SUPER_ADMIN.
enum ApproverRole { certifier, approver }

extension ApproverRoleX on ApproverRole {
  String get code => this == ApproverRole.certifier ? 'CERTIFIER' : 'APPROVER';

  String get label => this == ApproverRole.certifier ? 'role_certifier'.tr : 'role_approver'.tr;
}

String _initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final letters = parts.where((p) => p.isNotEmpty).map((p) => p[0]).take(2);
  return letters.join().toUpperCase();
}

double? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

String? _strOrNull(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// One-line summary of a stock request (in / out / transfer / adjustment):
/// "+5 × USB-C Cable • Warehouse A", "5 × Cable • A → B", with the adjustment
/// reason appended when there is one.
String _stockDetail(
  String type,
  Map<String, dynamic> product,
  List<Map<String, dynamic>> rows,
  RequestLookups lookups,
) {
  String name(Map<String, dynamic> row) {
    final fromRow = (row['productName'] ?? '').toString();
    if (fromRow.isNotEmpty) return fromRow;
    final fromProduct = (product['productName'] ?? '').toString();
    return fromProduct.isNotEmpty ? fromProduct : (row['productCode'] ?? product['productCode'] ?? '').toString();
  }

  final lines = <String>[];
  for (final row in rows) {
    final qty = _num(row['quantity'])?.round() ?? 0;
    final variant = (row['variantCode'] ?? '').toString();
    final label = variant.isEmpty ? name(row) : '${name(row)} ($variant)';
    switch (type) {
      case 'STOCK_IN':
        lines.add('+$qty × $label • ${lookups.warehouse(row['warehouseCode']?.toString())}');
      case 'STOCK_OUT':
        lines.add('-$qty × $label • ${lookups.warehouse(row['warehouseCode']?.toString())}');
      case 'STOCK_ADJUSTMENT':
        final sign = (row['adjustmentType'] ?? '') == 'DECREASE' ? '-' : '+';
        final reason = (row['adjustmentReason'] ?? '').toString().trim();
        lines.add(
          '$sign$qty × $label • ${lookups.warehouse(row['warehouseCode']?.toString())}'
          '${reason.isEmpty ? '' : ' ($reason)'}',
        );
      case 'STOCK_TRANSFER':
        lines.add(
          '$qty × $label • ${lookups.warehouse(row['fromWarehouseCode']?.toString())}'
          ' → ${lookups.warehouse(row['toWarehouseCode']?.toString())}',
        );
      default:
        lines.add('$qty × $label');
    }
  }
  return lines.join(' • ');
}

/// One step of a request's approval chain, as returned by `GET /requests`.
class ApproverData {
  const ApproverData({
    required this.userId,
    required this.name,
    required this.staffId,
    required this.step,
    required this.role,
    required this.status,
    this.remark,
    this.actionDate,
    this.canAct = false,
  });

  final String userId;
  final String name;
  final String staffId;
  final int step;
  final ApproverRole role;
  final ApproverStatus status;
  final String? remark;
  final DateTime? actionDate;

  /// True only for the person whose turn it is and who is signed in now —
  /// the server decides this, the app just obeys it.
  final bool canAct;

  String get initials => _initialsOf(name.isEmpty ? staffId : name);

  factory ApproverData.fromJson(Map<String, dynamic> json) {
    ApproverStatus status;
    switch ((json['status'] ?? '').toString()) {
      case 'PENDING':
        status = ApproverStatus.pending;
      case 'APPROVED':
        status = ApproverStatus.approved;
      case 'REJECTED':
        status = ApproverStatus.rejected;
      default:
        status = ApproverStatus.waiting;
    }
    final remark = (json['remark'] as String?)?.trim();
    return ApproverData(
      userId: (json['userId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      staffId: (json['staffId'] ?? '').toString(),
      step: (json['step'] as num?)?.toInt() ?? 0,
      role: json['actionType'] == 'CERTIFIER' ? ApproverRole.certifier : ApproverRole.approver,
      status: status,
      remark: (remark == null || remark.isEmpty) ? null : remark,
      actionDate: DateTime.tryParse((json['actionDate'] ?? '').toString()),
      canAct: json['canAct'] == true,
    );
  }
}

/// A user the requester may add to the approval chain
/// (`GET /requests/approver-candidates`).
class ApproverCandidate {
  const ApproverCandidate({
    required this.id,
    required this.staffId,
    required this.name,
    required this.roles,
    required this.canApprove,
  });

  final String id;
  final String staffId;
  final String name;
  final List<String> roles;

  /// Only ADMIN / MANAGER / SUPER_ADMIN may be an APPROVER.
  final bool canApprove;

  String get label => roles.isEmpty ? name : '$name (${roles.join(', ')})';

  factory ApproverCandidate.fromJson(Map<String, dynamic> json) => ApproverCandidate(
        id: (json['id'] ?? '').toString(),
        staffId: (json['staffId'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        roles: (json['roles'] as List? ?? const []).map((e) => e.toString()).toList(),
        canApprove: json['canApprove'] == true,
      );
}

/// code -> display name for the master data a request only stores by code.
class RequestLookups {
  const RequestLookups({
    this.categories = const {},
    this.brands = const {},
    this.suppliers = const {},
    this.warehouses = const {},
  });

  final Map<String, String> categories;
  final Map<String, String> brands;
  final Map<String, String> suppliers;
  final Map<String, String> warehouses;

  static String? _pick(Map<String, String> map, String? code) {
    if (code == null || code.isEmpty) return null;
    return map[code] ?? code;
  }

  String? category(String? code) => _pick(categories, code);
  String? brand(String? code) => _pick(brands, code);
  String? supplier(String? code) => _pick(suppliers, code);
  String warehouse(String? code) => _pick(warehouses, code) ?? '';
}

/// One request row in the Requests list.
class RequestItemData {
  const RequestItemData({
    required this.requesterName,
    required this.typeLabel,
    required this.requestId,
    required this.detail,
    required this.submittedAgo,
    required this.status,
    this.createdAt,
    this.productPayload,
    this.rejectReason,
    this.id,
    this.approvers = const [],
    this.canAct = false,
    this.remark,
  });

  final String requesterName;
  final String typeLabel;
  final String requestId;
  final String detail;
  final String submittedAgo;
  final RequestStatus status;

  /// When the request was made (null for local-only rows).
  final DateTime? createdAt;

  /// Full structured product (with variants, when the product has them) —
  /// lets Request Detail render a real breakdown instead of just the flat
  /// [detail] caption. Null for request types that don't carry a product.
  final StockItemData? productPayload;

  /// Set when [status] is [RequestStatus.rejected] — the reason the
  /// approver gave.
  final String? rejectReason;

  /// Server id (uuid). Null for local-only rows.
  final String? id;

  final List<ApproverData> approvers;

  /// Whether the signed-in user may approve/reject this request right now.
  final bool canAct;

  /// The requester's own note, if any.
  final String? remark;

  bool get isRemote => id != null;

  /// The approver whose turn it currently is (null once decided).
  ApproverData? get currentApprover {
    for (final a in approvers) {
      if (a.status == ApproverStatus.pending) return a;
    }
    return null;
  }

  RequestItemData copyWith({RequestStatus? status, String? rejectReason}) {
    return RequestItemData(
      requesterName: requesterName,
      typeLabel: typeLabel,
      requestId: requestId,
      detail: detail,
      submittedAgo: submittedAgo,
      status: status ?? this.status,
      createdAt: createdAt,
      productPayload: productPayload,
      rejectReason: rejectReason ?? this.rejectReason,
      id: id,
      approvers: approvers,
      canAct: canAct,
      remark: remark,
    );
  }

  /// Up to two initials for the avatar tile, e.g. "Sopheak Ros" -> "SR".
  String get initials => _initialsOf(requesterName);

  static const _typeLabels = {
    'PRODUCT_CREATE': 'Product Create',
    'PRODUCT_UPDATE': 'Product Update',
    'VARIANT_CREATE': 'Variant Create',
    'VARIANT_UPDATE': 'Variant Update',
    'STOCK_IN': 'Stock In',
    'STOCK_OUT': 'Stock Out',
    'STOCK_TRANSFER': 'Stock Transfer',
    'STOCK_ADJUSTMENT': 'Adjustment',
  };

  static String _ago(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time.toLocal());
    if (diff.inMinutes < 1) return 'time_just_now'.tr;
    if (diff.inHours < 1) return 'time_minutes_ago'.trParams({'n': '${diff.inMinutes}'});
    if (diff.inDays < 1) return 'time_hours_ago'.trParams({'n': '${diff.inHours}'});
    if (diff.inDays < 7) return 'time_days_ago'.trParams({'n': '${diff.inDays}'});
    final t = time.toLocal();
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';
  }

  /// Builds a row from one `GET /requests` entry.
  factory RequestItemData.fromJson(Map<String, dynamic> json, [RequestLookups lookups = const RequestLookups()]) {
    final type = (json['requestType'] ?? '').toString();
    final product = json['product'] is Map ? Map<String, dynamic>.from(json['product'] as Map) : null;
    final stockRows = (json['stock'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final variantRows = <Map<String, dynamic>>[];
    final seenVariants = <String>{};
    for (final raw in (json['variants'] as List? ?? const [])) {
      final row = Map<String, dynamic>.from(raw as Map);
      final code = (row['variantCode'] ?? '').toString();
      if (seenVariants.add(code)) variantRows.add(row);
    }

    int qtyOf(Iterable<Map<String, dynamic>> rows) =>
        rows.fold<int>(0, (sum, r) => sum + (_num(r['quantity'])?.round() ?? 0));

    List<WarehouseStockData> warehouseStocksOf(Iterable<Map<String, dynamic>> rows) {
      return rows
          .where((r) => (r['warehouseCode'] ?? '').toString().isNotEmpty)
          .map((r) {
            final code = r['warehouseCode'].toString();
            final location = (r['location'] as String?)?.trim();
            return WarehouseStockData(
              warehouseCode: code,
              warehouseName: lookups.warehouse(code),
              quantity: _num(r['quantity'])?.round() ?? 0,
              location: (location == null || location.isEmpty) ? null : location,
            );
          })
          .toList();
    }

    String warehouseSummary(List<WarehouseStockData> stocks) {
      final names = stocks.map((s) => s.warehouseName).where((n) => n.isNotEmpty).toSet();
      if (names.isEmpty) return '';
      return names.length == 1 ? names.first : '${names.length} warehouses';
    }

    StockStatus statusFor(int qty, int? min) {
      if (qty <= 0) return StockStatus.outOfStock;
      if (min != null && min > 0 && qty <= min) return StockStatus.lowStock;
      return StockStatus.inStock;
    }

    StockItemData? payload;
    String detail = '';
    if (product != null) {
      final name = (product['productName'] ?? '').toString();
      final code = (product['productCode'] ?? '').toString();
      final sku = (product['productSku'] ?? '').toString();
      final minRaw = _num(product['minimumStock'])?.round();
      final minStock = (minRaw != null && minRaw > 0) ? minRaw : null;
      final totalQty = qtyOf(stockRows);

      if (type == 'PRODUCT_CREATE') {
        final variants = variantRows.map((v) {
          final vCode = (v['variantCode'] ?? '').toString();
          final rows = stockRows.where((r) => (r['variantCode'] ?? '').toString() == vCode).toList();
          final stocks = warehouseStocksOf(rows);
          final qty = qtyOf(rows);
          return ProductVariantData(
            variantCode: vCode,
            variantName: (v['variantName'] ?? '').toString(),
            sku: (v['variantSku'] ?? '').toString(),
            barcode: v['variantBarcode']?.toString(),
            warehouse: warehouseSummary(stocks),
            quantity: qty,
            status: statusFor(qty, minStock),
            costPrice: _num(v['variantCostPrice']),
            sellingPrice: _num(v['variantSellingPrice']),
            warehouseStocks: stocks,
            imageUrl: _strOrNull(v['variantImage']),
          );
        }).toList();
        final stocks = warehouseStocksOf(stockRows);
        payload = StockItemData(
          code: code.isEmpty ? null : code,
          name: name,
          sku: sku,
          warehouse: warehouseSummary(stocks),
          quantity: totalQty,
          status: statusFor(totalQty, minStock),
          variants: variants,
          category: lookups.category(product['categoryCode']?.toString()),
          brand: lookups.brand(product['brandCode']?.toString()),
          unit: (product['unit'] ?? 'PCS').toString(),
          costPrice: _num(product['productCostPrice']),
          sellingPrice: _num(product['productSellingPrice']),
          supplier: lookups.supplier(product['supplierCode']?.toString()),
          description: product['description']?.toString(),
          minStock: minStock,
          barcode: product['productBarcode']?.toString(),
          warehouseStocks: variants.isEmpty ? stocks : const [],
          imageUrl: _strOrNull(product['productImage']),
        );
      }

      final parts = <String>[name.isNotEmpty ? name : code];
      if (variantRows.isNotEmpty) {
        parts.add('${variantRows.length} variant${variantRows.length == 1 ? '' : 's'}');
      }
      if (stockRows.isNotEmpty) parts.add('Qty $totalQty');
      if (sku.isNotEmpty) parts.add('SKU $sku');
      final brand = lookups.brand(product['brandCode']?.toString());
      if (brand != null) parts.add(brand);
      detail = parts.where((p) => p.isNotEmpty).join(' • ');

      // Stock movements read better as "+5 × Name • Warehouse" than as a
      // product summary.
      if (type.startsWith('STOCK_') && stockRows.isNotEmpty) {
        detail = _stockDetail(type, product, stockRows, lookups);
      }
    }

    final status = switch ((json['status'] ?? '').toString()) {
      'APPROVED' => RequestStatus.approved,
      'REJECTED' => RequestStatus.rejected,
      _ => RequestStatus.pending,
    };

    final approvers = (json['approvers'] as List? ?? const [])
        .map((e) => ApproverData.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.step.compareTo(b.step));

    String? rejectReason;
    if (status == RequestStatus.rejected) {
      for (final a in approvers) {
        if (a.status == ApproverStatus.rejected) rejectReason = a.remark;
      }
    }

    final remark = (json['remark'] as String?)?.trim();
    return RequestItemData(
      id: json['id']?.toString(),
      requesterName: (json['requesterName'] ?? '').toString(),
      typeLabel: _typeLabels[type] ?? type,
      requestId: '#${json['requestNo'] ?? ''}',
      detail: detail,
      submittedAgo: _ago(DateTime.tryParse((json['createdAt'] ?? '').toString())),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString())?.toLocal(),
      status: status,
      productPayload: payload,
      rejectReason: rejectReason,
      approvers: approvers,
      canAct: approvers.any((a) => a.canAct),
      remark: (remark == null || remark.isEmpty) ? null : remark,
    );
  }
}
