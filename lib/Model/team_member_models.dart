/// One row under More > Team Members, as returned by `GET /users`.
/// [roleName] is the backend role's name (e.g. STAFF); [roleId] is that
/// role's UUID, needed when changing it via `PUT /users/:id/role`. [id] and
/// [staffId] are null only for locally-built items that never hit the API.
class TeamMemberData {
  const TeamMemberData({
    required this.name,
    required this.email,
    required this.roleName,
    this.phone,
    this.id,
    this.staffId,
    this.roleId,
  });

  final String name;
  final String email;
  final String roleName;
  final String? phone;
  final String? id;
  final String? staffId;
  final String? roleId;

  /// Maps one item of `GET /users`'s `data` array: `profile` holds the
  /// name/email/phone and `userRoles[0].role` the (single) assigned role.
  factory TeamMemberData.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? const {};
    final userRoles = json['userRoles'] as List? ?? const [];
    Map<String, dynamic>? role;
    if (userRoles.isNotEmpty) {
      role = (userRoles.first as Map<String, dynamic>)['role'] as Map<String, dynamic>?;
    }
    final firstName = profile['firstName']?.toString() ?? '';
    final lastName = profile['lastName']?.toString() ?? '';

    return TeamMemberData(
      id: json['id']?.toString(),
      staffId: json['staffId']?.toString(),
      name: '$firstName $lastName'.trim(),
      email: profile['email']?.toString() ?? '',
      phone: profile['phone']?.toString(),
      roleName: role?['name']?.toString() ?? '',
      roleId: role?['id']?.toString(),
    );
  }

  /// Up to two initials for the avatar tile, e.g. "Visal Khem" -> "VK".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.where((p) => p.isNotEmpty).map((p) => p[0]).take(2);
    return letters.join().toUpperCase();
  }

  TeamMemberData copyWith({String? name, String? email, String? roleName, String? phone}) {
    return TeamMemberData(
      name: name ?? this.name,
      email: email ?? this.email,
      roleName: roleName ?? this.roleName,
      phone: phone ?? this.phone,
      id: id,
      staffId: staffId,
      roleId: roleId,
    );
  }
}

/// A role the Team Member form can offer, from `GET /roles`.
class RoleOption {
  const RoleOption({required this.id, required this.name});

  final String id;
  final String name;

  factory RoleOption.fromJson(Map<String, dynamic> json) {
    return RoleOption(id: json['id'].toString(), name: json['name'].toString());
  }
}

/// Response of `POST /users`. The backend also emails these to the new
/// member, but returns them so the creator can hand them over directly.
class CreatedMember {
  const CreatedMember({required this.staffId, required this.temporaryPassword});

  final String staffId;
  final String temporaryPassword;

  factory CreatedMember.fromJson(Map<String, dynamic> json) {
    return CreatedMember(
      staffId: json['staffId']?.toString() ?? '',
      temporaryPassword: json['temporaryPassword']?.toString() ?? '',
    );
  }
}
