import 'package:get/get.dart';
import 'package:stock_management/Controller/login_controller.dart';
import 'package:stock_management/Controller/new_password_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Permanent: Login <-> New Password jump between each other with
    // Get.offAllNamed, which clears the whole route stack. A non-permanent
    // controller disposes its TextEditingControllers in onClose() as soon as
    // that happens, and a stray tap/focus event landing right at that moment
    // crashes with "A TextEditingController was used after being disposed"
    // (same class of bug as the bottom-nav tabs — see StockBinding).
    if (!Get.isRegistered<LoginController>()) {
      Get.put<LoginController>(LoginController(), permanent: true);
    }
    if (!Get.isRegistered<NewPasswordController>()) {
      Get.put<NewPasswordController>(NewPasswordController(), permanent: true);
    }
  }
}
