import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/team_member_form_controller.dart';
import 'package:stock_management/Model/team_member_models.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/app_text_field.dart';

/// Add/Edit Team Member — reached from More > Team Members (+Add or a
/// row's edit icon). See [TeamMemberFormController].
class TeamMemberFormScreen extends GetView<TeamMemberFormController> {
  const TeamMemberFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header,
          Expanded(
            child: SafeArea(
              top: false,
              child: Form(
                key: controller.formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    _sectionLabel('section_member_details'.tr),
                    const SizedBox(height: 10),
                    _detailsCard,
                    const SizedBox(height: 18),
                    _sectionLabel('section_role'.tr),
                    const SizedBox(height: 10),
                    _roleChips,
                    const SizedBox(height: 24),
                    Obx(
                      () => AppButton(
                        label: controller.isEditing ? 'action_save_changes'.tr : 'action_add_team_member'.tr,
                        isLoading: controller.isSaving.value,
                        onPressed: controller.save,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _header {
    return AppScreenHeader(
      children: [
        Row(
          children: [
            Material(
              color: AppScreenHeader.onHeaderSurface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: Get.back,
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppScreenHeader.onHeader),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              controller.isEditing ? 'edit_team_member_title'.tr : 'add_team_member_title'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
    );
  }

  Widget get _detailsCard {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          AppTextField(
            label: 'field_full_name'.tr,
            controller: controller.nameController,
            enabled: !controller.isEditing,
            hintText: 'hint_full_name_example'.tr,
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'validation_required'.tr;
              if (value.split(RegExp(r'\s+')).length < 2) return 'validation_full_name_two_words'.tr;
              return null;
            },
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_email'.tr,
            controller: controller.emailController,
            enabled: !controller.isEditing,
            hintText: 'hint_email_example'.tr,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'validation_required'.tr : null,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_phone'.tr,
            controller: controller.phoneController,
            enabled: !controller.isEditing,
            hintText: 'hint_optional'.tr,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget get _roleChips {
    return Obx(() {
      if (controller.isLoadingRoles.value && controller.roleOptions.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(8),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      final roles = controller.roleOptions;
      if (roles.isEmpty) {
        return Text(
          'no_roles_yet_hint'.tr,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
        );
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final role in roles) _roleChip(role)],
      );
    });
  }

  Widget _roleChip(RoleOption role) {
    final isActive = controller.selectedRoleId.value == role.id;
    return Material(
      color: isActive ? AppColors.brand600 : AppColors.cardBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => controller.selectRole(role.id),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? AppColors.brand600 : AppColors.border),
          ),
          child: Text(
            role.name,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
