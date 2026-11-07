import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/scan_qr_controller.dart';
import 'package:stock_management/Controller/stock_form_controller.dart';
import 'package:stock_management/Controller/stock_movement_controller.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_text_field.dart';

/// Reached from the bottom nav's center button on every main tab. Scans a
/// barcode/QR (or takes one typed manually) and either opens the matching
/// product or offers to add it as new — see [ScanQrController].
class ScanQrScreen extends GetView<ScanQrController> {
  const ScanQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller.cameraController,
            onDetect: _handleDetection,
          ),
          _scrim(alignment: Alignment.topCenter),
          _scrim(alignment: Alignment.bottomCenter),
          _viewfinder,
          _manualEntryDim,
          SafeArea(
            child: Column(
              children: [
                _topBar,
                const Spacer(),
                _bottomPanel,
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleDetection(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue?.trim() ?? '';
    if (code.isEmpty) return;
    _resolve(code);
  }

  void _resolve(String code) {
    if (!controller.beginHandling()) return;
    // Two-stage capture animation before acting on the result: the QR
    Future.delayed(const Duration(milliseconds: 420), () async {
      controller.confirmMatch();
      // Look the code up while the check tick plays.
      final lookup = _lookup(code);
      await Future.delayed(const Duration(milliseconds: 480));
      final result = await lookup;
      if (result.error != null) {
        Get.bottomSheet(
          _MessageSheet(message: result.error!),
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
        ).whenComplete(controller.resumeScanning);
        return;
      }
      final match = result.product;
      if (match != null) {
        Get.bottomSheet(
          _ProductActionsSheet(product: match, onPick: (open) => _openAction(match, open)),
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
        ).whenComplete(controller.resumeScanning);
        return;
      }
      Get.bottomSheet(
        _NotFoundSheet(
          code: code,
          // Only roles that may create products can add the unknown code.
          onAddNew: can(Perm.productCreate)
              ? () {
                  Get.back();
                  Get.offNamed(Routes.addProduct, arguments: code);
                }
              : null,
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      ).whenComplete(controller.resumeScanning);
    });
  }

  /// Closes the actions sheet, then opens the chosen screen in place of the
  /// scanner. Stock forms get the scanned product as their first line.
  void _openAction(StockItemData product, _ScanAction action) {
    Get.back();
    switch (action) {
      case _ScanAction.detail:
        Get.offNamed(Routes.productDetail, arguments: product);
      case _ScanAction.stockIn:
        StockFormController.pendingProduct = product;
        Get.offNamed(Routes.stockIn, arguments: StockMovementDirection.stockIn);
      case _ScanAction.stockOut:
        StockFormController.pendingProduct = product;
        Get.offNamed(Routes.stockOut, arguments: StockMovementDirection.stockOut);
      case _ScanAction.transfer:
        StockFormController.pendingProduct = product;
        Get.offNamed(Routes.transfer);
      case _ScanAction.adjust:
        StockFormController.pendingProduct = product;
        Get.offNamed(Routes.adjust);
    }
  }

  Future<_LookupResult> _lookup(String code) async {
    try {
      return _LookupResult(product: await controller.lookupRemote(code));
    } on ApiException catch (e) {
      return _LookupResult(error: e.message);
    }
  }

  // Dims the frozen camera frame while the manual-entry sheet is open —
  // the camera itself is paused (see ScanQrController.pauseForOverlay), this
  // just makes that visually obvious instead of looking like a stuck frame.
  Widget get _manualEntryDim {
    return Obx(
      () => IgnorePointer(
        child: AnimatedOpacity(
          opacity: controller.isPausedForOverlay.value ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(color: Colors.black.withValues(alpha: 0.55)),
        ),
      ),
    );
  }

  Widget _scrim({required Alignment alignment}) {
    final isTop = alignment == Alignment.topCenter;
    return Align(
      alignment: alignment,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
            end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget get _topBar {
    // Fixed-width leading/trailing slots + an Expanded, ellipsized title —
    // guaranteed not to overflow even at larger system text sizes, unlike
    // a Row of Spacer()s sized purely by the title's natural width.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          _roundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: Get.back),
          Expanded(
            child: Text(
              'scan_title'.tr,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          Obx(
            () => _roundIconButton(
              icon: controller.torchOn.value ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              onTap: controller.toggleTorch,
              active: controller.torchOn.value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({required IconData icon, required VoidCallback onTap, bool active = false}) {
    return Material(
      color: active ? AppColors.brand600 : Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget get _viewfinder {
    // Alignment.y: 0 = centered, negative = shifted up (-1 would be the top
    // edge). Nudge this closer to -1 to raise the frame further.
    return Align(
      alignment: const Alignment(0, -0.15),
      child: Builder(
        builder: (context) {
          // Clamped to the screen width so this can't overflow on a narrow
          // device instead of assuming a fixed 260 always fits.
          final size = math.min(260.0, MediaQuery.sizeOf(context).width - 80);
          return Obx(() {
            final captured = controller.captured.value;
            final showTick = controller.showTick.value;
            final frameColor = captured ? AppColors.success : Colors.white;
            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Idle "still looking" sweep — paused (and hidden) the
                  // instant a code is caught, see the badge below.
                  if (!captured) _ScanLine(size: size),
                  Positioned(top: 0, left: 0, child: _cornerMark(top: true, left: true, color: frameColor)),
                  Positioned(top: 0, right: 0, child: _cornerMark(top: true, left: false, color: frameColor)),
                  Positioned(bottom: 0, left: 0, child: _cornerMark(top: false, left: true, color: frameColor)),
                  Positioned(bottom: 0, right: 0, child: _cornerMark(top: false, left: false, color: frameColor)),
                  // "Caught it" — a QR badge jumps into the center the
                  Center(
                    child: AnimatedScale(
                      scale: captured ? 1 : 0.2,
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.elasticOut,
                      child: AnimatedOpacity(
                        opacity: captured ? 1 : 0,
                        duration: const Duration(milliseconds: 160),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                          child: showTick
                              ? _captureBadge(
                                  key: const ValueKey('tick'),
                                  color: AppColors.success,
                                  icon: Icons.check_rounded,
                                )
                              : _captureBadge(
                                  key: const ValueKey('qr'),
                                  color: AppColors.brand600,
                                  icon: Icons.qr_code_2_rounded,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  Widget _captureBadge({required Key key, required Color color, required IconData icon}) {
    return Container(
      key: key,
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: 32, color: Colors.white),
    );
  }

  Widget _cornerMark({required bool top, required bool left, required Color color}) {
    const side = 34.0;
    const thickness = 4.0;
    const radius = Radius.circular(18);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: side,
      height: side,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: color, width: thickness) : BorderSide.none,
          bottom: !top ? BorderSide(color: color, width: thickness) : BorderSide.none,
          left: left ? BorderSide(color: color, width: thickness) : BorderSide.none,
          right: !left ? BorderSide(color: color, width: thickness) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? radius : Radius.zero,
          topRight: top && !left ? radius : Radius.zero,
          bottomLeft: !top && left ? radius : Radius.zero,
          bottomRight: !top && !left ? radius : Radius.zero,
        ),
      ),
    );
  }

  Widget get _bottomPanel {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'scan_instruction'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _openManualEntry,
            icon: const Icon(Icons.keyboard_alt_outlined, size: 16, color: Colors.white),
            label: Text(
              'action_enter_code_manually'.tr,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }

  void _openManualEntry() {
    final codeController = TextEditingController();
    controller.pauseForOverlay();
    Get.bottomSheet(
      _ManualEntrySheet(
        codeController: codeController,
        onSubmit: () {
          final code = codeController.text.trim();
          if (code.isEmpty) return;
          Get.back(); // close the manual-entry sheet first.
          _resolve(code);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).whenComplete(controller.resumeFromOverlay);
  }
}

/// Fallback to scanning — types the code the camera would otherwise read.
class _ManualEntrySheet extends StatelessWidget {
  const _ManualEntrySheet({required this.codeController, required this.onSubmit});

  final TextEditingController codeController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    // Get.bottomSheet's route already wraps every sheet in
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(
              'action_enter_code_manually'.tr,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'field_sku_or_barcode'.tr,
              controller: codeController,
              hintText: 'hint_sku_barcode_example'.tr,
              prefixIcon: Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            AppButton(label: 'action_look_up'.tr, onPressed: onSubmit),
          ],
        ),
      ),
    );
  }
}

/// Shown when a scanned/typed code has no match on the Stock list.
class _NotFoundSheet extends StatelessWidget {
  const _NotFoundSheet({required this.code, this.onAddNew});

  final String code;

  /// Null when this role can't create products — then only the message and
  /// "Scan again" are shown.
  final VoidCallback? onAddNew;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: AppColors.warningBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(Icons.search_off_rounded, size: 26, color: AppColors.warning),
            ),
            const SizedBox(height: 16),
            Text(
              'not_found_title'.tr,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              onAddNew == null ? 'scan_not_found_no_permission'.tr : 'not_found_message'.trParams({'code': code}),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            if (onAddNew != null) ...[
              AppButton(label: 'action_add_as_new_product'.tr, icon: Icons.add_rounded, onPressed: onAddNew),
              const SizedBox(height: 10),
            ],
            AppButton(label: 'action_scan_again'.tr, variant: AppButtonVariant.secondary, onPressed: Get.back),
          ],
        ),
      ),
    );
  }
}

enum _ScanAction { detail, stockIn, stockOut, transfer, adjust }

/// What to do with the scanned product: open it, or start a stock movement
/// with it already filled in (quantity is still typed by hand).
class _ProductActionsSheet extends StatelessWidget {
  const _ProductActionsSheet({required this.product, required this.onPick});

  final StockItemData product;
  final void Function(_ScanAction action) onPick;

  @override
  Widget build(BuildContext context) {
    final canAdjust = can(Perm.stockAdjust) || can(Perm.requestCreate);
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              [product.sku, '${'field_quantity'.tr}: ${product.quantity}'].where((e) => e.isNotEmpty).join(' • '),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'scan_action_view'.tr,
              icon: Icons.visibility_outlined,
              onPressed: () => onPick(_ScanAction.detail),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'stock_in'.tr,
                    icon: Icons.call_made_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => onPick(_ScanAction.stockIn),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'stock_out'.tr,
                    icon: Icons.call_received_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => onPick(_ScanAction.stockOut),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'qa_transfer'.tr,
                    icon: Icons.swap_horiz_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => onPick(_ScanAction.transfer),
                  ),
                ),
                if (canAdjust) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'qa_adjust'.tr,
                      icon: Icons.tune_rounded,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => onPick(_ScanAction.adjust),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            AppButton(label: 'action_scan_again'.tr, variant: AppButtonVariant.text, onPressed: Get.back),
          ],
        ),
      ),
    );
  }
}

class _LookupResult {
  const _LookupResult({this.product, this.error});

  final StockItemData? product;
  final String? error;
}

/// Shown when the lookup itself failed (offline, expired session, no
/// permission) — different from "no product has this code".
class _MessageSheet extends StatelessWidget {
  const _MessageSheet({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 32, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 20),
            AppButton(label: 'action_scan_again'.tr, onPressed: Get.back),
          ],
        ),
      ),
    );
  }
}

/// The horizontal line that sweeps up and down inside the viewfinder while idle, signaling "still looking for a code".
class _ScanLine extends StatefulWidget {
  const _ScanLine({required this.size});

  /// Side length of the (square) viewfinder this line sweeps inside.
  final double size;

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const lineHeight = 3.0;
    const inset = 10.0;
    final travel = widget.size - lineHeight - inset * 2;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Positioned(
          left: inset,
          right: inset,
          top: inset + _controller.value * travel,
          child: Container(
            height: lineHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
              boxShadow: [
                BoxShadow(color: Colors.white.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
