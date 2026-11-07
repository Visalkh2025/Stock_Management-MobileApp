import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';

/// Status of a customer order (placed by a customer in the Mini App, or by
/// staff). Values match the API's `CustomerOrderStatus`.
enum CoStatus {
  pendingReview('PENDING_REVIEW', 'co_status_pending'),
  waitingCustomer('WAITING_CUSTOMER', 'co_status_waiting_customer'),
  confirmed('CONFIRMED', 'co_status_confirmed'),
  waitingStock('WAITING_STOCK', 'co_status_waiting_stock'),
  processing('PROCESSING', 'co_status_processing'),
  outForDelivery('OUT_FOR_DELIVERY', 'co_status_out'),
  delivered('DELIVERED', 'co_status_delivered'),
  completed('COMPLETED', 'co_status_completed'),
  rejected('REJECTED', 'co_status_rejected'),
  cancelled('CANCELLED', 'co_status_cancelled');

  const CoStatus(this.apiValue, this.labelKey);

  final String apiValue;
  final String labelKey;

  static CoStatus fromApi(String? value) =>
      CoStatus.values.firstWhere((s) => s.apiValue == value, orElse: () => CoStatus.pendingReview);

  Color get color {
    switch (this) {
      case CoStatus.pendingReview:
      case CoStatus.waitingCustomer:
      case CoStatus.waitingStock:
        return AppColors.warning;
      case CoStatus.confirmed:
      case CoStatus.processing:
      case CoStatus.outForDelivery:
        return AppColors.brand700;
      case CoStatus.delivered:
      case CoStatus.completed:
        return AppColors.success;
      case CoStatus.rejected:
        return AppColors.danger;
      case CoStatus.cancelled:
        return AppColors.muted;
    }
  }

  Color get background {
    switch (this) {
      case CoStatus.pendingReview:
      case CoStatus.waitingCustomer:
      case CoStatus.waitingStock:
        return AppColors.warningBg;
      case CoStatus.confirmed:
      case CoStatus.processing:
      case CoStatus.outForDelivery:
        return AppColors.brand50;
      case CoStatus.delivered:
      case CoStatus.completed:
        return AppColors.successBg;
      case CoStatus.rejected:
        return AppColors.dangerBg;
      case CoStatus.cancelled:
        return AppColors.pageBg;
    }
  }

  /// Orders still being worked on (not finished, not turned down).
  bool get isOpen => this != CoStatus.completed && this != CoStatus.rejected && this != CoStatus.cancelled;
}

double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

String? _str(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

/// The newest payment that has a photo attached.
String? _proofUrl(dynamic payments) {
  if (payments is! List) return null;
  String? found;
  for (final p in payments) {
    if (p is Map) {
      final url = _str(p['proofImageUrl']);
      if (url != null) found = url;
    }
  }
  return found;
}

String? _staffName(dynamic user) {
  if (user is! Map) return null;
  final profile = user['profile'];
  if (profile is Map) {
    final name = '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();
    if (name.isNotEmpty) return name;
  }
  return _str(user['email']);
}

/// Who placed the order: the person's name, the company, and how to reach them.
class CoCustomer {
  const CoCustomer({this.name, this.company, this.phone, this.telegram});

  final String? name;
  final String? company;
  final String? phone;
  final String? telegram;

  /// Best single label for lists.
  String get title => name ?? company ?? telegram ?? '—';

  factory CoCustomer.fromJson(dynamic json) {
    if (json is! Map) return const CoCustomer();
    final first = _str(json['firstName']);
    final last = _str(json['lastName']);
    final full = [first, last].whereType<String>().join(' ').trim();
    final username = _str(json['telegramUsername']);
    return CoCustomer(
      name: _str(json['contactName']) ?? (full.isEmpty ? null : full),
      company: _str(json['companyName']),
      phone: _str(json['phone']),
      telegram: username == null ? null : '@$username',
    );
  }
}

/// One row of the customer-order list.
class CustomerOrderSummary {
  const CustomerOrderSummary({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.customer,
    required this.itemCount,
    required this.totalAmount,
    required this.isPaid,
    required this.fromMiniApp,
    this.createdAt,
  });

  final String id;
  final String orderNo;
  final CoStatus status;
  final CoCustomer customer;
  final int itemCount;
  final double totalAmount;
  final bool isPaid;
  final bool fromMiniApp;
  final DateTime? createdAt;

  factory CustomerOrderSummary.fromJson(Map<String, dynamic> json) => CustomerOrderSummary(
        id: '${json['id']}',
        orderNo: _str(json['orderNo']) ?? '',
        status: CoStatus.fromApi(_str(json['status'])),
        customer: CoCustomer.fromJson(json['customer']),
        itemCount: (json['items'] as List? ?? const []).length,
        totalAmount: _num(json['totalAmount']),
        isPaid: json['paymentStatus'] == 'PAID',
        fromMiniApp: json['source'] != 'STAFF',
        createdAt: _date(json['createdAt']),
      );
}

class CoItem {
  const CoItem({
    required this.id,
    required this.name,
    this.variantName,
    required this.requested,
    required this.approved,
    required this.waiting,
    required this.unitPrice,
    required this.subtotal,
    this.warehouseName,
  });

  final String id;
  final String name;
  final String? variantName;
  final double requested;
  final double approved;
  final double waiting;
  final double unitPrice;
  final double subtotal;
  final String? warehouseName;

  String get title => variantName == null ? name : '$name • $variantName';

  factory CoItem.fromJson(Map<String, dynamic> json) => CoItem(
        id: '${json['id']}',
        name: _str((json['product'] as Map?)?['name']) ?? '—',
        variantName: _str((json['variant'] as Map?)?['name']),
        requested: _num(json['requestedQuantity']),
        approved: _num(json['approvedQuantity']),
        waiting: _num(json['waitingQuantity']),
        unitPrice: _num(json['unitPrice']),
        subtotal: _num(json['subtotal']),
        warehouseName: _str((json['warehouse'] as Map?)?['name']),
      );
}

/// One line of the order's history (status changes, questions, answers).
class CoMessage {
  const CoMessage({required this.sender, required this.senderName, required this.message, this.createdAt});

  /// CUSTOMER / STAFF / SYSTEM.
  final String sender;
  final String? senderName;
  final String message;
  final DateTime? createdAt;

  factory CoMessage.fromJson(Map<String, dynamic> json) => CoMessage(
        sender: _str(json['senderType']) ?? 'SYSTEM',
        senderName: _str(json['senderName']),
        message: _str(json['message']) ?? '',
        createdAt: _date(json['createdAt']),
      );
}

class CustomerOrderDetail {
  const CustomerOrderDetail({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.customer,
    required this.items,
    required this.messages,
    required this.totalAmount,
    required this.subtotalAmount,
    required this.discountAmount,
    required this.discountPercent,
    this.tierName,
    required this.isPaid,
    this.paidAt,
    this.paidByName,
    this.proofImageUrl,
    required this.deliveryDone,
    required this.fromMiniApp,
    this.address,
    this.remark,
    this.staffNotes,
    this.createdAt,
  });

  final String id;
  final String orderNo;
  final CoStatus status;
  final CoCustomer customer;
  final List<CoItem> items;
  final List<CoMessage> messages;
  final double totalAmount;
  final double subtotalAmount;
  final double discountAmount;
  final double discountPercent;
  final String? tierName;
  final bool isPaid;
  final DateTime? paidAt;
  final String? paidByName;

  /// Photo of the transaction attached when the payment was recorded.
  final String? proofImageUrl;
  final bool deliveryDone;
  final bool fromMiniApp;
  final String? address;
  final String? remark;
  final String? staffNotes;
  final DateTime? createdAt;

  bool get hasDiscount => discountAmount > 0;

  factory CustomerOrderDetail.fromJson(Map<String, dynamic> json) {
    final place = [json['commune'], json['district'], json['province']].map(_str).whereType<String>().toList();
    final street = _str(json['deliveryAddress']);
    final address = [if (street != null) street, ...place].join(', ');
    final total = _num(json['totalAmount']);
    return CustomerOrderDetail(
      id: '${json['id']}',
      orderNo: _str(json['orderNo']) ?? '',
      status: CoStatus.fromApi(_str(json['status'])),
      customer: CoCustomer.fromJson(json['customer']),
      items: [
        for (final e in (json['items'] as List? ?? const [])) CoItem.fromJson(Map<String, dynamic>.from(e as Map)),
      ],
      messages: [
        for (final e in (json['messages'] as List? ?? const [])) CoMessage.fromJson(Map<String, dynamic>.from(e as Map)),
      ],
      totalAmount: total,
      subtotalAmount: json['subtotalAmount'] == null ? total : _num(json['subtotalAmount']),
      discountAmount: _num(json['loyaltyDiscountAmount']),
      discountPercent: _num(json['loyaltyDiscountPercent']),
      tierName: _str(json['loyaltyTierName']),
      isPaid: json['paymentStatus'] == 'PAID',
      paidAt: _date(json['paidAt']),
      paidByName: _staffName(json['paidReceivedBy']),
      proofImageUrl: _proofUrl(json['payments']),
      deliveryDone: json['deliveryStatus'] == 'DELIVERED',
      fromMiniApp: json['source'] != 'STAFF',
      address: address.isEmpty ? null : address,
      remark: _str(json['remark']),
      staffNotes: _str(json['staffNotes']),
      createdAt: _date(json['createdAt']),
    );
  }
}

String coMoney(double v) => '\$${v.toStringAsFixed(2)}';

String coQty(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

String coDateTime(DateTime? d) {
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}
