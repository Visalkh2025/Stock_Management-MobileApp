import 'package:get/get.dart';
import 'package:stock_management/Controller/team_members_controller.dart';

class TeamMembersBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TeamMembersController>()) {
      // First open: onInit() loads the list.
      Get.put<TeamMembersController>(TeamMembersController(), permanent: true);
    } else {
      // The controller is permanent, so onInit() won't run again — refresh
      // on every open so a different signed-in user never sees a stale list.
      Get.find<TeamMembersController>().load();
    }
  }
}
