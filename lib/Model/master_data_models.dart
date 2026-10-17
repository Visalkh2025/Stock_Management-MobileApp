/// Simple named master-data records — Category, Brand, Supplier, Warehouse —
/// managed from More > Manage. Each comes from the NestJS API (`id` and
/// `code` are server-side; the API addresses a record by `id`, and other
/// endpoints refer to it by `code`).
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

  factory SupplierData.fromJson(Map<String, dynamic> json) => SupplierData(
        id: (json['id'] ?? '').toString(),
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        contactPerson: _text(json['contactPerson']),
        phone: _text(json['phone']),
        email: _text(json['email']),
        address: _text(json['address']),
      );
}

class WarehouseData implements MasterRecord {
  const WarehouseData({required this.id, required this.code, required this.name, this.location});

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
      );
}
