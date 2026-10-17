import 'package:stock_management/Config/api_config.dart';
import 'package:stock_management/Model/team_member_models.dart';
import 'package:stock_management/Services/api_client.dart';

class TeamService {
  TeamService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// `GET /users` is paginated (max 100 per page) — walk every page so the
  /// screen's local search sees the whole team.
  Future<List<TeamMemberData>> fetchMembers() async {
    final members = <TeamMemberData>[];
    var page = 1;
    while (true) {
      final json = await _apiClient.get(ApiConfig.users, query: {'page': page, 'limit': 100}) as Map<String, dynamic>;
      final data = json['data'] as List? ?? const [];
      members.addAll(data.map((e) => TeamMemberData.fromJson(Map<String, dynamic>.from(e as Map))));

      final meta = json['meta'] as Map<String, dynamic>? ?? const {};
      if (meta['hasNextPage'] != true) break;
      page++;
    }
    return members;
  }

  /// `GET /roles` with no query returns a plain array; with a page/limit it
  /// returns `{data, meta}` — accept both.
  Future<List<RoleOption>> fetchRoles() async {
    final json = await _apiClient.get(ApiConfig.roles);
    final list = json is List ? json : (json as Map<String, dynamic>)['data'] as List? ?? const [];
    return list.map((e) => RoleOption.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<CreatedMember> createMember({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? roleId,
  }) async {
    final json = await _apiClient.post(
      ApiConfig.users,
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'roleId': ?roleId,
      },
    );
    return CreatedMember.fromJson(json as Map<String, dynamic>);
  }

  Future<void> updateRole({required String userId, required String roleId}) async {
    await _apiClient.put(ApiConfig.userRole(userId), body: {'roleId': roleId});
  }
}
