import 'package:get/get.dart';
import 'package:stock_management/Controller/team_member_form_controller.dart';

class TeamMemberFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeamMemberFormController>(() => TeamMemberFormController());
  }
}
