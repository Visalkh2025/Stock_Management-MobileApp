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

  int get count => _items.length;

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
    final list = query.isEmpty
        ? _items.toList()
        : _items.where((item) {
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

  /// The backend has no "remove user" endpoint yet, so removing here would
  /// only hide the row until the next refresh. Say so instead of faking it.
  void delete(TeamMemberData item) {
    AppSnackbar.warning(
      'coming_soon_title'.tr,
      'team_delete_unavailable_message'.tr,
    );
  }
}
