import 'package:get/get.dart';
import 'package:stock_management/Controller/help_support_controller.dart';

/// More > Help & Support routes here (Routes.helpSupport).
class HelpSupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelpSupportController>(() => HelpSupportController());
  }
}
