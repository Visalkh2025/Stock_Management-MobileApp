import 'package:get/get.dart';
import 'package:stock_management/Controller/settings_controller.dart';

/// More > Settings routes here (Routes.settings).
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
