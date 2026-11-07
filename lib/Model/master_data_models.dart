/// Simple named master-data records — Category, Brand, Supplier, Warehouse — managed from More > Manage.
library;

/// What every master-data record has — lets one list/form controller serve
/// all of them (see MasterListController / MasterFormController).
abstract class MasterRecord {
  String get id;
  String get code;
  String get name;
}

String? _text(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

class CategoryData implements MasterRecord {
  const CategoryData({required this.id, required this.code, required this.name, this.description});

  @override
  final String id;
  @override
  final String code;
  @override
  final String name;
  final String? description;

  factory CategoryData.fromJson(Map<String, dynamic> json) => CategoryData(
        id: (json['id'] ?? '').toString(),
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        description: _text(json['description']),
      );
}

class BrandData implements MasterRecord {
  const BrandData({required this.id, required this.code, required this.name, this.description});

  @override
  final String id;
  @override
  final String code;
  @override
  final String name;
  final String? description;

  factory BrandData.fromJson(Map<String, dynamic> json) => BrandData(
        id: (json['id'] ?? '').toString(),
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        description: _text(json['description']),
      );
}

class SupplierData implements MasterRecord {
  const SupplierData({
    required this.id,
    required this.code,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.platform,
    this.platformLink,
    this.country,
  });

  @override
  final String id;
  @override
  final String code;
  @override
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;

  /// TELEGRAM, WHATSAPP, FACEBOOK ... (see [SupplierFormController.platforms]).
  final String? platform;
  final String? platformLink;
  final String? country;

  factory SupplierData.fromJson(Map<String, dynamic> json) => SupplierData(
        id: (json['id'] ?? '').toString(),
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        contactPerson: _text(json['contactPerson']),
        phone: _text(json['phone']),
        email: _text(json['email']),
        address: _text(json['address']),
        platform: _text(json['platform']),
        platformLink: _text(json['platformLink']),
        country: _text(json['country']),
      );
}

class WarehouseData implements MasterRecord {
  const WarehouseData({
    required this.id,
    required this.code,
    required this.name,
    this.location,
    this.capacity,
    this.usedQuantity = 0,
    this.incomingQuantity = 0,
  });

  /// Most units the warehouse may hold (null = no limit).
  final double? capacity;

  /// Units in stock now, and units still to arrive on open purchase orders.
  final double usedQuantity;
  final double incomingQuantity;

  @override
  final String id;
  @override
  final String code;
  @override
  final String name;

  /// The warehouse's `address` on the server.
  final String? location;

  factory WarehouseData.fromJson(Map<String, dynamic> json) => WarehouseData(
        id: (json['id'] ?? '').toString(),
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        location: _text(json['address']),
        capacity: _toDoubleOrNull(json['capacity']),
        usedQuantity: _toDoubleOrNull(json['usedQuantity']) ?? 0,
        incomingQuantity: _toDoubleOrNull(json['incomingQuantity']) ?? 0,
      );
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
