import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/profile_controller.dart';
import 'package:stock_management/Model/profile_models.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/app_text_field.dart';
import 'package:stock_management/View/Components/user_avatar.dart';

/// Reached from the More screen's profile row and the Home header's
/// avatar. One screen, two modes — a read-only view and an edit form —
/// toggled by [ProfileController.isEditing]; see that controller for the
/// shared [UserProfileData] both other screens also read.
class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          _header,
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() => controller.isEditing.value ? _editBody : _viewBody),
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
            Expanded(
              child: Text(
                'profile_title'.tr,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
              ),
            ),
            Obx(
              () => controller.isEditing.value
                  ? _headerAction(label: 'action_cancel'.tr, onTap: controller.cancelEditing)
                  : _headerAction(icon: Icons.edit_outlined, onTap: controller.startEditing),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerAction({String? label, IconData? icon, required VoidCallback onTap}) {
    return Material(
      color: AppScreenHeader.onHeaderSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 38,
          padding: EdgeInsets.symmetric(horizontal: label != null ? 14 : 0),
          width: label != null ? null : 38,
          alignment: Alignment.center,
          child: label != null
              ? Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppScreenHeader.onHeader))
              : Icon(icon, size: 17, color: AppScreenHeader.onHeader),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- View

  Widget get _viewBody {
    return Obx(() {
      final p = controller.profile.value;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Center(child: UserAvatar(profile: p, size: 96)),
          const SizedBox(height: 14),
          Text(p.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 3),
          Text(p.role, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
          const SizedBox(height: 22),
          _infoCard(p),
          const SizedBox(height: 22),
          _signOutButton,
        ],
      );
    });
  }

  Widget _infoCard(UserProfileData p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.brand900.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          _infoRow(icon: Icons.mail_outline_rounded, label: 'field_email'.tr, value: p.email),
          const Divider(height: 1, thickness: 1, color: AppColors.border, indent: 14, endIndent: 14),
          _infoRow(icon: Icons.call_outlined, label: 'field_phone'.tr, value: (p.phone == null || p.phone!.isEmpty) ? 'value_not_set'.tr : p.phone!),
        ],
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: AppColors.brand700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
                const SizedBox(height: 1),
                Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card-style row (matches the info/menu rows elsewhere) instead of a
  // plain outlined button — a soft danger-tinted fill, a white icon chip,
  // and a trailing chevron so it reads as one more tappable row, not an
  // odd stand-alone outline.
  Widget get _signOutButton {
    return Material(
      color: AppColors.dangerBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: controller.signOut,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.danger.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
                alignment: Alignment.center,
                child: const Icon(Icons.logout_rounded, size: 17, color: AppColors.danger),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'sign_out'.tr,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.danger),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.danger.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Edit

  Widget get _editBody {
    return Form(
      key: controller.formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Center(child: _avatarPicker),
          const SizedBox(height: 22),
          AppTextField(
            label: 'field_full_name'.tr,
            controller: controller.nameController,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'validation_required'.tr : null,
          ),
          const SizedBox(height: 14),
          AppTextField(label: 'field_role_title'.tr, controller: controller.roleController),
          const SizedBox(height: 14),
          AppTextField(
            label: 'field_email'.tr,
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'validation_required'.tr;
              if (!value.contains('@') || !value.contains('.')) return 'validation_email_invalid'.tr;
              return null;
            },
          ),
          const SizedBox(height: 14),
          AppTextField(label: 'field_phone'.tr, controller: controller.phoneController, keyboardType: TextInputType.phone),
          const SizedBox(height: 24),
          AppButton(label: 'action_save_changes'.tr, onPressed: controller.save),
          const SizedBox(height: 10),
          AppButton(label: 'action_cancel'.tr, variant: AppButtonVariant.secondary, onPressed: controller.cancelEditing),
        ],
      ),
    );
  }

  Widget get _avatarPicker {
    return Obx(() {
      final image = controller.draftAvatar.value;
      return GestureDetector(
        onTap: _showAvatarSourceSheet,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.pageBg,
                border: Border.all(color: AppColors.brand700.withAlpha(30)),
                image: image != null ? DecorationImage(image: FileImage(image), fit: BoxFit.cover) : null,
              ),
              alignment: Alignment.center,
              child: image == null
                  ? Text(
                      controller.profile.value.initials,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.brand700),
                    )
                  : null,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.brand600,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBg, width: 3),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showAvatarSourceSheet() {
    final context = Get.context;
    if (context == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.brand700),
              title: Text('action_take_photo'.tr),
              onTap: () {
                Get.back();
                controller.pickAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.brand700),
              title: Text('action_choose_from_gallery'.tr),
              onTap: () {
                Get.back();
                controller.pickAvatar(ImageSource.gallery);
              },
            ),
            if (controller.draftAvatar.value != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: Text('action_remove_photo'.tr),
                onTap: () {
                  Get.back();
                  controller.removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }
}
