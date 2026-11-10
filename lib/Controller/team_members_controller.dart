import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Model/team_member_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/team_service.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';

/// List behind More > Team Members, loaded from `GET /users`.
class TeamMembersController extends GetxController {
  final TeamService _service = TeamService();

  final _items = <TeamMemberData>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  int get count => _items.where((item) => !item.isInactive).length;

  // Highest role first; any other role name goes after STAFF.
  static const _roleOrder = ['SUPER_ADMIN', 'ADMIN', 'MANAGER', 'STAFF'];

  int _rank(TeamMemberData item) {
    final role = item.roleName.trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');
    final index = _roleOrder.indexOf(role);
    return index == -1 ? _roleOrder.length : index;
  }

  /// Search result ordered Super Admin > Admin > Manager > Staff, then by name.
  List<TeamMemberData> get filteredItems {
    final query = searchQuery.value.trim().toLowerCase();
    // Removed (deactivated) members are hidden here; an admin can bring them back on the web.
    final active = _items.where((item) => !item.isInactive);
    final list = query.isEmpty
        ? active.toList()
        : active.where((item) {
            return item.name.toLowerCase().contains(query) || item.email.toLowerCase().contains(query);
          }).toList();
    list.sort((a, b) {
      final byRole = _rank(a).compareTo(_rank(b));
      return byRole != 0 ? byRole : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      _items.assignAll(await _service.fetchMembers());
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void setSearch(String value) => searchQuery.value = value;

  void openAdd() => Get.toNamed(Routes.teamMemberForm);

  void openEdit(TeamMemberData item) => Get.toNamed(Routes.teamMemberForm, arguments: item);

  /// "Removes" a member: the server deactivates the account (no more sign-in,
  /// sessions revoked) and keeps their history.
  Future<void> delete(TeamMemberData item) async {
    final id = item.id;
    if (id == null) return;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('team_remove_title'.trParams({'name': item.name})),
        content: Text('team_remove_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('action_cancel'.tr)),
          TextButton(onPressed: () => Get.back(result: true), child: Text('team_remove_action'.tr)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deactivateMember(id);
      await load();
      AppSnackbar.success('team_removed_title'.tr, 'team_removed_message'.trParams({'name': item.name}));
    } on ApiException catch (e) {
      AppSnackbar.error('team_remove_failed_title'.tr, e.message);
    }
  }
}
