import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Model/team_member_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/team_service.dart';

/// List behind More > Team Members, loaded from `GET /users`. Add/Edit
/// happens on [TeamMemberFormController]'s screen, which calls [load] again
/// after a successful save so the list always mirrors the server. Search is
/// done locally over the loaded list.
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

  List<TeamMemberData> get filteredItems {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return _items.toList();
    return _items.where((item) {
      return item.name.toLowerCase().contains(query) || item.email.toLowerCase().contains(query);
    }).toList();
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
    Get.snackbar(
      'coming_soon_title'.tr,
      'team_delete_unavailable_message'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
