import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/profile_controller.dart';
import 'package:stock_management/Controller/team_members_controller.dart';
import 'package:stock_management/Model/team_member_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/team_service.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';

/// Add/Edit form behind More > Team Members. Get.arguments is the
/// [TeamMemberData] being edited, or null when adding a new one.
///
/// Add -> `POST /users` with the chosen role. Edit -> only the role can
/// change (`PUT /users/:id/role`); the backend has no endpoint for editing
/// name/email/phone, so those fields are read-only while editing.
class TeamMemberFormController extends GetxController {
  /// Mirrors the backend's ROLE_ASSIGNMENT_MAP (users.service.ts) so the form only offers roles the signed-in user may actually assign.
  static const Map<String, List<String>> _assignableRoles = {
    'SUPER_ADMIN': ['ADMIN', 'MANAGER', 'STAFF'],
    'ADMIN': ['MANAGER', 'STAFF'],
    'MANAGER': ['STAFF'],
  };

  final TeamService _service = TeamService();

  TeamMemberData? get _original => Get.arguments as TeamMemberData?;

  bool get isEditing => _original != null;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final roleOptions = <RoleOption>[].obs;
  final selectedRoleId = RxnString();
  final isLoadingRoles = false.obs;
  final isSaving = false.obs;

  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    final original = _original;
    if (original != null) {
      nameController.text = original.name;
      emailController.text = original.email;
      phoneController.text = original.phone ?? '';
      selectedRoleId.value = original.roleId;
    }
    loadRoles();
  }

  void selectRole(String roleId) => selectedRoleId.value = roleId;

  String get _currentUserRole {
    if (!Get.isRegistered<ProfileController>()) return '';
    return Get.find<ProfileController>().profile.value.role;
  }

  Future<void> loadRoles() async {
    isLoadingRoles.value = true;
    try {
      final all = await _service.fetchRoles();
      final myRole = _currentUserRole;

      // SUPER_ADMIN may set any role when editing (backend bypass); when
      // the signed-in role is unknown, show everything and let the backend
      // decide.
      final List<RoleOption> visible;
      if (myRole.isEmpty || (isEditing && myRole == 'SUPER_ADMIN')) {
        visible = all;
      } else {
        final allowed = _assignableRoles[myRole] ?? const <String>[];
        visible = all.where((role) => allowed.contains(role.name)).toList();
      }
      roleOptions.assignAll(visible);

      if (!isEditing && !visible.any((role) => role.id == selectedRoleId.value)) {
        final staff = visible.where((role) => role.name == 'STAFF').firstOrNull;
        selectedRoleId.value = (staff ?? visible.firstOrNull)?.id;
      }
    } on ApiException catch (e) {
      AppSnackbar.error('team_members_load_failed_title'.tr, e.message);
    } finally {
      isLoadingRoles.value = false;
    }
  }

  TeamMembersController get _members {
    if (!Get.isRegistered<TeamMembersController>()) {
      Get.put(TeamMembersController(), permanent: true);
    }
    return Get.find<TeamMembersController>();
  }

  Future<void> save() async {
    // Editing only changes the role, and name/email/phone are read-only
    // there, so skip validating them.
    if (!isEditing && !(formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();

    isSaving.value = true;
    try {
      final original = _original;
      if (original != null) {
        final roleId = selectedRoleId.value;
        if (original.id != null && roleId != null && roleId != original.roleId) {
          await _service.updateRole(userId: original.id!, roleId: roleId);
        }
        await _members.load();
        isSaving.value = false;
        Get.back();
        return;
      }

      // Backend needs a first and last name; the form has one "full name"
      // field (validated to contain at least two words).
      final parts = nameController.text.trim().split(RegExp(r'\s+'));
      final phone = phoneController.text.trim();
      final created = await _service.createMember(
        firstName: parts.first,
        lastName: parts.skip(1).join(' '),
        email: emailController.text.trim(),
        phone: phone.isEmpty ? null : phone,
        roleId: selectedRoleId.value,
      );
      await _members.load();
      isSaving.value = false;
      Get.back();
      _showCreatedDialog(created);
    } on ApiException catch (e) {
      AppSnackbar.error('team_member_save_failed_title'.tr, e.message);
    } finally {
      if (!isClosed) isSaving.value = false;
    }
  }

  /// The backend emails the temporary password, but also returns it — show
  /// it once so the creator can hand it over if the email doesn't arrive.
  void _showCreatedDialog(CreatedMember created) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'team_member_created_title'.tr,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SelectableText(
          'team_member_created_message'.trParams({
            'staffId': created.staffId,
            'password': created.temporaryPassword,
          }),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              'team_member_created_close'.tr,
              style: const TextStyle(color: AppColors.brand600, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
