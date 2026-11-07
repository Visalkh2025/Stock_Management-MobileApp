import 'package:get/get.dart';

/// Which tab is active on More > Roles & Permissions — Roles vs. the Permissions catalog.
enum RbacTab { roles, permissions }

class RbacHubController extends GetxController {
  final selectedTab = RbacTab.roles.obs;

  void selectTab(RbacTab tab) => selectedTab.value = tab;
}
