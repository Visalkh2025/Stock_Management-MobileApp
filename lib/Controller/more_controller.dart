import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/locale_controller.dart';
import 'package:stock_management/Controller/profile_controller.dart';
import 'package:stock_management/Controller/purchase_orders_controller.dart';
import 'package:stock_management/Model/profile_models.dart';

class MoreController extends GetxController {
  // Registered permanently in main() before runApp — same guarded-singleton
  // pattern used everywhere else in this app (see SettingsController).
  LocaleController get _locale {
    if (!Get.isRegistered<LocaleController>()) {
      Get.put(LocaleController(), permanent: true);
    }
    return Get.find<LocaleController>();
  }

  bool get isKhmer => _locale.isKhmer;

  // Quick-toggle for the flag button in the header — flips straight to
  // the other language, same underlying call the Settings screen uses.
  void toggleLanguage() => _locale.changeLocale(isKhmer ? 'en' : 'km');

  // Shared with the Profile screen and the Home header — same guarded
  // singleton pattern as StockController/RequestController, so an edit
  // saved on the Profile screen shows up here without any extra wiring.
  ProfileController get _profileController {
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController(), permanent: true);
    }
    return Get.find<ProfileController>();
  }

  UserProfileData get profile => _profileController.profile.value;

  // Live count of purchase orders, same guarded-singleton pattern as
  // _profileController.
  PurchaseOrdersController get _purchaseOrders {
    if (!Get.isRegistered<PurchaseOrdersController>()) {
      Get.put(PurchaseOrdersController(), permanent: true);
    }
    return Get.find<PurchaseOrdersController>();
  }

  int get purchaseOrderCount => _purchaseOrders.totalCount;

  void openProfile() {
    Get.toNamed(Routes.profile);
  }

  void openManage() => Get.toNamed(Routes.manage);

  void openPurchaseOrders() => Get.toNamed(Routes.purchaseOrders);

  void openReports() => Get.toNamed(Routes.reports);

  void openTeamMembers() => Get.toNamed(Routes.teamMembers);

  void openRolesPermissions() => Get.toNamed(Routes.rolesPermissions);

  void openSettings() => Get.toNamed(Routes.settings);

  void openHelpSupport() => Get.toNamed(Routes.helpSupport);

  void signOut() {
    _profileController.signOut();
  }
}
