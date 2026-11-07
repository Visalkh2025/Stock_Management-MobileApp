/// One line of the stock history: a Stock In, Stock Out, Transfer or
/// Adjustment (`GET /stock-adjustments/history`).
class StockHistoryEntry {
  const StockHistoryEntry({
    required this.id,
    required this.kind,
    required this.at,
    required this.productCode,
    required this.productName,
    required this.quantity,
    this.productId,
    this.variantName,
    this.fromWarehouse,
    this.toWarehouse,
    this.reason,
    this.byStaff,
    this.requestNo,
  });

  final String id;

  /// 'IN' | 'OUT' | 'TRANSFER' | 'ADJUSTMENT'
  final String kind;
  final DateTime? at;
  final String? productId;
  final String productCode;
  final String productName;
  final String? variantName;
  final String? fromWarehouse;
  final String? toWarehouse;
  final double quantity;
  final String? reason;
  final String? byStaff;
  final String? requestNo;

  factory StockHistoryEntry.fromJson(Map<String, dynamic> json) {
    String? text(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return StockHistoryEntry(
      id: (json['id'] ?? '').toString(),
      kind: (json['kind'] ?? '').toString(),
      at: json['at'] == null ? null : DateTime.tryParse(json['at'].toString())?.toLocal(),
      productId: text(json['productId']),
      productCode: (json['productCode'] ?? '').toString(),
      productName: (json['productName'] ?? '').toString(),
      variantName: text(json['variantName']),
      fromWarehouse: text(json['fromWarehouse']),
      toWarehouse: text(json['toWarehouse']),
      quantity: double.tryParse('${json['quantity']}') ?? 0,
      reason: text(json['reason']),
      byStaff: text(json['byStaff']),
      requestNo: text(json['requestNo']),
    );
  }
}

/// One page of [StockHistoryEntry].
class StockHistoryPage {
  const StockHistoryPage({required this.entries, required this.total, required this.hasNextPage});

  final List<StockHistoryEntry> entries;
  final int total;
  final bool hasNextPage;

  factory StockHistoryPage.fromJson(Map<String, dynamic> json) => StockHistoryPage(
        entries: [
          for (final e in (json['data'] as List? ?? const []))
            StockHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)),
        ],
        total: (json['total'] as num?)?.toInt() ?? 0,
        hasNextPage: json['hasNextPage'] == true,
      );
}
