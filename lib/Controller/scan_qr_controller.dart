import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:stock_management/Controller/stock_controller.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/product_service.dart';

/// Backs the Scan screen reached from the bottom nav's center button on every main tab.
class ScanQrController extends GetxController {
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  final torchOn = false.obs;

  // True right after a code is read — the camera stops and a QR-code
  // badge jumps into the center of the frame (see ScanQrScreen._viewfinder)
  // while the corner brackets turn green.
  final captured = false.obs;

  // True once that badge should swap from the QR icon to a check tick — set a beat after [captured] so the two play in sequence (jump in, then confirm) rather than both appearing at once.
  final showTick = false.obs;

  // True while a detected/typed code is being looked up and its result
  // (navigation, or the not-found sheet) is on screen — blocks the camera
  // from firing again on the same code until resumeScanning() is called.
  bool _handling = false;

  // True while the manual-entry sheet covers the scanner — drives the dim
  // overlay in ScanQrScreen. Separate from `captured`/`showTick`: nothing
  // was scanned, so none of that capture animation applies here.
  final isPausedForOverlay = false.obs;

  /// Pauses the camera while a modal (the manual-entry sheet) covers the
  /// scanner, so it can't fire onDetect — and burn battery — on a code
  /// caught in the background while the user is mid-typing.
  void pauseForOverlay() {
    isPausedForOverlay.value = true;
    cameraController.stop();
  }

  /// Resumes after [pauseForOverlay] — but only if a scanned code isn't
  /// already being handled (that owns the camera's stopped state instead).
  void resumeFromOverlay() {
    isPausedForOverlay.value = false;
    if (!_handling) cameraController.start();
  }

  void toggleTorch() {
    cameraController.toggleTorch();
    torchOn.value = !torchOn.value;
  }

  /// Call before acting on a scanned/typed code.
  bool beginHandling() {
    if (_handling) return false;
    _handling = true;
    captured.value = true;
    cameraController.stop();
    return true;
  }

  /// Call once the QR badge has had time to settle, to swap it for the
  /// confirming check tick.
  void confirmMatch() => showTick.value = true;

  /// Call once the not-found sheet closes (or is dismissed) to arm the
  /// camera for the next scan.
  void resumeScanning() {
    _handling = false;
    captured.value = false;
    showTick.value = false;
    cameraController.start();
  }

  final _products = ProductService();

  /// Server lookup by SKU / barcode / product or variant code (exact,
  /// case-insensitive). Returns null when nothing matches; any other
  /// failure (network, permission) is rethrown as [ApiException].
  Future<StockItemData?> lookupRemote(String code) async {
    try {
      return await _products.fetchByCode(code);
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  /// Local fallback over the already-loaded Stock list (used by the other
  /// forms that still resolve a code offline).
  StockItemData? lookup(String code) {
    final stock = Get.isRegistered<StockController>()
        ? Get.find<StockController>()
        : Get.put(StockController(), permanent: true);
    return stock.findByCode(code);
  }

  @override
  void onClose() {
    cameraController.dispose();
    super.onClose();
  }
}
