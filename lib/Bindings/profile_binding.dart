import 'package:get/get.dart';
import 'package:stock_management/Controller/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Permanent + guarded, not lazyPut — ProfileController is a shared
    // singleton (see its doc comment), so re-visiting this route must not
    // recreate it and lose whatever's currently saved.
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController(), permanent: true);
    }
  }
}
