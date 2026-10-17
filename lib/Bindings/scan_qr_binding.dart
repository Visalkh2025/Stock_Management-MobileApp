import 'package:get/get.dart';
import 'package:stock_management/Controller/scan_qr_controller.dart';

class ScanQrBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScanQrController>(() => ScanQrController());
  }
}
