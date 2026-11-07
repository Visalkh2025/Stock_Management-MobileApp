import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/profile_controller.dart';
import 'package:stock_management/Services/auth_service.dart';

/// Decides where the app goes after the splash.
class SplashController {
  const SplashController._();

  /// Stays signed in across restarts: if a login is stored and still valid
  /// (or can be refreshed), go to Home with the user's permissions loaded.
  static Future<String> resolveRoute() async {
    try {
      final user = await AuthService().restoreSession().timeout(const Duration(seconds: 10));
      if (user == null) return Routes.login;
      final profile = Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : Get.put(ProfileController(), permanent: true);
      profile.loadFromAuthUser(user);
      return Routes.home;
    } catch (_) {
      return Routes.login;
    }
  }
}
