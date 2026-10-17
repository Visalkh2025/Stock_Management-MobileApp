import 'package:get/get.dart';

/// Which tab is active on More > Roles & Permissions — Roles vs. the
/// Permissions catalog. Purely local UI state for the hub screen; the
/// actual data lives in [RolesController]/[PermissionsController], each
/// reached from here as a guarded singleton the same way every other
/// pair of related screens in this app cross-references each other.
enum RbacTab { roles, permissions }

class RbacHubController extends GetxController {
  final selectedTab = RbacTab.roles.obs;

  void selectTab(RbacTab tab) => selectedTab.value = tab;
}
