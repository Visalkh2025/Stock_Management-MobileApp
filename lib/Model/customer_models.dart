import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';

/// Registration status of a customer. Values match the API's `CustomerStatus`.
enum CustomerStatus {
  active('ACTIVE', 'cu_status_active'),
  pending('PENDING', 'cu_status_pending'),
  suspended('SUSPENDED', 'cu_status_suspended'),
  blocked('BLOCKED', 'cu_status_blocked'),
  rejected('REJECTED', 'cu_status_rejected');

  const CustomerStatus(this.apiValue, this.labelKey);

  final String apiValue;
  final String labelKey;

  static CustomerStatus fromApi(String? value) =>
      CustomerStatus.values.firstWhere((s) => s.apiValue == value, orElse: () => CustomerStatus.active);

  Color get color {
    switch (this) {
      case CustomerStatus.active:
        return AppColors.success;
      case CustomerStatus.pending:
      case CustomerStatus.suspended:
        return AppColors.warning;
      case CustomerStatus.blocked:
      case CustomerStatus.rejected:
        return AppColors.danger;
    }
  }

  Color get background {
    switch (this) {
      case CustomerStatus.active:
        return AppColors.successBg;
      case CustomerStatus.pending:
      case CustomerStatus.suspended:
        return AppColors.warningBg;
      case CustomerStatus.blocked:
      case CustomerStatus.rejected:
        return AppColors.dangerBg;
    }
  }
}

double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

String? _str(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

/// A registered customer with their order totals (staff view).
class CustomerRow {
  const CustomerRow({
    required this.id,
    required this.title,
    required this.status,
    this.name,
    this.company,
    this.phone,
    this.address,
    this.telegram,
    this.telegramAccounts = const [],
    this.rejectionReason,
    this.tierName,
    this.discountPercent = 0,
    this.orderCount = 0,
    this.completedOrders = 0,
    this.totalSpent = 0,
    this.totalQuantity = 0,
    this.lastOrderAt,
    this.joinedAt,
  });

  final String id;

  /// Best single label for lists.
  final String title;
  final CustomerStatus status;
  final String? name;
  final String? company;
  final String? phone;
  final String? address;
  final String? telegram;
  final List<String> telegramAccounts;
  final String? rejectionReason;
  final String? tierName;
  final double discountPercent;
  final int orderCount;
  final int completedOrders;
  final double totalSpent;
  final double totalQuantity;
  final DateTime? lastOrderAt;
  final DateTime? joinedAt;

  factory CustomerRow.fromJson(Map<String, dynamic> json) {
    final first = _str(json['firstName']);
    final last = _str(json['lastName']);
    final full = [first, last].whereType<String>().join(' ').trim();
    final name = _str(json['contactName']) ?? (full.isEmpty ? null : full);
    final company = _str(json['companyName']);
    final username = _str(json['telegramUsername']);

    final accounts = <String>[];
    final rawAccounts = json['telegramAccounts'];
    if (rawAccounts is List) {
      for (final a in rawAccounts) {
        if (a is! Map) continue;
        final u = _str(a['telegramUsername']);
        final label = u != null ? '@$u' : _str(a['firstName']);
        if (label != null) accounts.add(label);
      }
    }
    final telegram = username != null ? '@$username' : (accounts.isEmpty ? null : accounts.first);

    final place = [json['commune'], json['district'], json['province']].map(_str).whereType<String>();
    final address = [_str(json['address']), ...place].whereType<String>().join(', ');

    final tier = (json['manualTierOverride'] ?? json['loyaltyTier']);

    return CustomerRow(
      id: '${json['id']}',
      title: name ?? company ?? telegram ?? '—',
      status: CustomerStatus.fromApi(_str(json['status'])),
      name: name,
      company: company,
      phone: _str(json['phone']),
      address: address.isEmpty ? null : address,
      telegram: telegram,
      telegramAccounts: accounts,
      rejectionReason: _str(json['rejectionReason']),
      tierName: tier is Map ? _str(tier['name']) : null,
      discountPercent: tier is Map ? _num(tier['discountPercent']) : 0,
      orderCount: _num(json['orderCount']).round(),
      completedOrders: _num(json['completedOrdersCount']).round(),
      totalSpent: _num(json['lifetimeSpending']),
      totalQuantity: _num(json['totalQuantityPurchased']),
      lastOrderAt: _date(json['lastOrderAt']),
      joinedAt: _date(json['createdAt']),
    );
  }
}
