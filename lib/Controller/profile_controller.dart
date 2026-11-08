import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Services/order_watcher.dart';
import 'package:stock_management/Services/push_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/request_controller.dart';
import 'package:stock_management/Controller/stock_controller.dart';
import 'package:stock_management/Model/auth_models.dart';
import 'package:stock_management/Model/profile_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/auth_service.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';

class ProfileController extends GetxController {
  final Rx<UserProfileData> profile = const UserProfileData(
    name: '',
    role: '',
    email: '',
  ).obs;

  final AuthService _authService = AuthService();

  /// Permission codes of the signed-in user (from `POST /auth/login`).
  final permissions = <String>[].obs;

  bool can(String code) => permissions.contains(code);

  /// Who is signed in (id + role names) — e.g. to tell whether a purchase
  /// order was sent to *this* person for approval.
  String userId = '';
  List<String> roles = const [];
  bool get isSuperAdmin => roles.contains('SUPER_ADMIN');

  /// Maps the backend's user shape (already returned in full by
  /// `POST /auth/login` — no extra request needed) onto the [profile] this
  /// controller exposes to the rest of the app.
  void loadFromAuthUser(AuthUser user) {
    permissions.assignAll(user.permissions);
    userId = user.id;
    roles = List<String>.from(user.roles);
    profile.value = UserProfileData(
      name: user.fullName,
      role: user.roles.isNotEmpty ? user.roles.first : '',
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
    );
  }

  // ---- Edit-form state. Only live while isEditing is true — populated
  // fresh from `profile` each time editing starts, discarded on cancel.
  final nameController = TextEditingController();
  final roleController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final draftAvatar = Rxn<File>();
  final formKey = GlobalKey<FormState>();
  final isEditing = false.obs;

  final _picker = ImagePicker();

  final isSaving = false.obs;

  void startEditing() {
    final p = profile.value;
    nameController.text = p.name;
    roleController.text = p.role;
    emailController.text = p.email;
    phoneController.text = p.phone ?? '';
    draftAvatar.value = null;
    isEditing.value = true;
  }

  void cancelEditing() => isEditing.value = false;

  Future<void> pickAvatar(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 800);
    if (picked != null) draftAvatar.value = File(picked.path);
  }

  /// Drops the photo just picked (the saved photo stays until a new one is uploaded).
  void removeAvatar() => draftAvatar.value = null;

  /// Saves name / email / phone (and the new photo, if one was picked) on the server.
  Future<void> save() async {
    if (isSaving.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;
    isSaving.value = true;
    try {
      var user = await _authService.updateProfile(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
      );
      final photo = draftAvatar.value;
      if (photo != null) user = await _authService.uploadAvatar(photo);
      profile.value = UserProfileData(
        name: user.fullName,
        role: profile.value.role,
        email: user.email,
        phone: user.phone,
        avatarUrl: user.avatarUrl,
      );
      isEditing.value = false;
      AppSnackbar.success('profile_updated_title'.tr, 'profile_updated_message'.tr);
    } on ApiException catch (e) {
      AppSnackbar.error('profile_update_failed'.tr, e.message);
    } catch (e) {
      AppSnackbar.error('profile_update_failed'.tr, '$e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> signOut() async {
    // Needs the access token, so before the session is cleared.
    await PushService.instance.unregister();
    OrderWatcher.instance.stop();
    await _authService.logout();
    permissions.clear();
    // The Stock list is cached in a permanent controller — drop it so the
    // next person to sign in loads their own data.
    if (Get.isRegistered<StockController>()) Get.delete<StockController>(force: true);
    if (Get.isRegistered<RequestController>()) Get.delete<RequestController>(force: true);
    Get.offAllNamed(Routes.login);
  }

  @override
  void onClose() {
    nameController.dispose();
    roleController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
