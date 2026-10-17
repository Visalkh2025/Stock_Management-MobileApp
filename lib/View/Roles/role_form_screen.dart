import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/role_form_controller.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/app_text_field.dart';

/// Add/Edit Role — reached from Roles & Permissions' Roles tab (+Add or a
/// card's edit icon). Only identity (name/description) — permission
/// assignment happens afterwards on [RolePermissionsScreen]. See
/// [RoleFormController].
class RoleFormScreen extends GetView<RoleFormController> {
  const RoleFormScreen({super.key});

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
                    _sectionLabel('section_role_details'.tr),
                    const SizedBox(height: 10),
                    _detailsCard,
                    if (!controller.isEditing) ...[
                      const SizedBox(height: 10),
                      _hintNote,
                    ],
                    const SizedBox(height: 24),
                    AppButton(
                      label: controller.isEditing ? 'action_save_changes'.tr : 'action_add_role'.tr,
                      onPressed: controller.save,
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
              controller.isEditing ? 'edit_role_title'.tr : 'add_role_title'.tr,
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
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
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
            label: 'field_role_name'.tr,
            controller: controller.nameController,
            hintText: 'hint_role_name_example'.tr,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'validation_required'.tr : null,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_description'.tr,
            controller: controller.descriptionController,
            hintText: 'hint_role_description_example'.tr,
            maxLines: 2,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'validation_required'.tr : null,
          ),
        ],
      ),
    );
  }

  Widget get _hintNote {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'role_hint_note'.tr,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}
