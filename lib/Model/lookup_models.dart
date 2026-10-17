/// One selectable row for a picker (category, brand, supplier, warehouse):
/// the backend takes the [code], the person sees the [name].
class LookupOption {
  const LookupOption({required this.id, required this.code, required this.name});

  final String id;
  final String code;
  final String name;

  factory LookupOption.fromJson(Map<String, dynamic> json) => LookupOption(
        id: (json['id'] ?? '').toString(),
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
      );

  @override
  bool operator ==(Object other) => other is LookupOption && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
