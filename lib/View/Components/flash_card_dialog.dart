import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/flash_card_models.dart';

/// The pop-up card that appears over a blurred Home when the app opens
/// (welcome message, news...). Content = [FlashCards.current]. Shown once per
/// app launch; tap the ✕ or outside the card to close.
class FlashCardDialog {
  const FlashCardDialog._();

  static bool _shownThisLaunch = false;

  static Future<void> showIfNeeded() async {
    if (_shownThisLaunch) return;
    final card = FlashCards.current;
    if (card == null) return;

    final key = 'flash_seen_${card.id}';
    SharedPreferences? prefs;
    if (card.showOnce) {
      try {
        prefs = await SharedPreferences.getInstance();
        if (prefs.getBool(key) ?? false) return;
      } catch (_) {
        // Can't read the flag: show it rather than hide it forever.
      }
    }

    final context = Get.overlayContext ?? Get.context;
    if (context == null || !context.mounted) return;
    _shownThisLaunch = true;
    try {
      await prefs?.setBool(key, true);
    } catch (_) {}
    if (!context.mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, _, _) => _FlashCardView(card: card),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeIn);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween<double>(begin: 0.9, end: 1).animate(curved), child: child),
        );
      },
    );
  }
}

class _FlashCardView extends StatelessWidget {
  const _FlashCardView({required this.card});

  final FlashCardData card;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = math.min(size.width - 64, 380.0);
    // Tall like a poster, but never taller than the screen allows.
    final height = math.min(width * 1.5, size.height - 220);

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: Get.back,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            color: Colors.black.withAlpha(60),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Absorbs taps so touching the card does not close it.
                GestureDetector(onTap: () {}, child: _card(width, height)),
                const SizedBox(height: 22),
                _closeButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _closeButton() {
    return GestureDetector(
      onTap: Get.back,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: const Color(0xFF6B6577).withAlpha(210), shape: BoxShape.circle),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _card(double width, double height) {
    final kicker = card.kickerKey.tr;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 40, offset: const Offset(0, 18))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Cream top + a slanted white band at the bottom.
            Positioned.fill(child: CustomPaint(painter: _BackdropPainter())),
            Positioned(
              top: 36,
              left: 26,
              right: 26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Text(
                        kicker,
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF16121F)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Color(0xFF6D28D9), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          card.badge,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      card.headlineKey.tr,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 54,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16121F),
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Little sparkle + bubbles, like the reference card.
            const Positioned(top: 120, left: 14, child: Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.brand400)),
            Positioned(top: 52, right: 28, child: _bubble(18)),
            Positioned(top: 38, right: 14, child: _bubble(8)),
            // The shelf illustration.
            Positioned.fill(
              top: height * 0.30,
              bottom: height * 0.18,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 304 / 310,
                  child: CustomPaint(painter: _ShelfPainter()),
                ),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 22,
              left: 24,
              child: Text(
                card.footerKey.tr,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF16121F)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(double d) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.brand400, width: 1.6)),
      );
}

/// Soft lilac top, white slanted band at the bottom.
class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF1ECFF), Color(0xFFF8F6FF)],
        ).createShader(Offset.zero & size),
    );
    final band = Path()
      ..moveTo(0, size.height * 0.80)
      ..lineTo(size.width, size.height * 0.70)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      band,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF6F5FA)],
        ).createShader(Offset(0, size.height * 0.7) & Size(size.width, size.height * 0.3)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The StockFlow shelf (the app icon) in brand purples. Drawn in a 304 x 310
/// design box so the shapes match the logo exactly.
class _ShelfPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 304;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(-104, -104);

    // Soft shadow on the floor.
    canvas.drawOval(
      const Rect.fromLTWH(120, 404, 272, 18),
      Paint()
        ..color = Colors.black.withAlpha(34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    RRect r(double x, double y, double w, double h, double rad) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(rad));

    final frame = Paint()..color = Color(0xFF6D28D9);
    canvas.drawRRect(r(104, 104, 16, 310, 8), frame);
    canvas.drawRRect(r(392, 104, 16, 310, 8), frame);
    canvas.drawRRect(r(104, 188, 304, 14, 7), frame);
    canvas.drawRRect(r(104, 288, 304, 14, 7), frame);
    canvas.drawRRect(r(104, 388, 304, 14, 7), frame);

    void box(double x, double y, double w, double h, Color c, {bool tape = true}) {
      canvas.drawRRect(r(x, y, w, h, 12), Paint()..color = c);
      if (tape) {
        canvas.drawRRect(
          r(x + w / 2 - 4, y, 8, h * 0.42, 4),
          Paint()..color = Colors.white.withAlpha(95),
        );
      }
    }

    box(140, 124, 74, 64, AppColors.brand600);
    box(228, 144, 54, 44, AppColors.brand300, tape: false);
    box(300, 132, 64, 56, AppColors.brand600, tape: false);
    box(140, 236, 56, 52, AppColors.brand300, tape: false);
    box(212, 216, 84, 72, AppColors.brand600);
    box(140, 324, 96, 64, AppColors.brand600);
    box(250, 338, 50, 50, AppColors.brand300, tape: false);

    final arrow = Path()
      ..moveTo(322, 238)
      ..relativeLineTo(50, 0)
      ..moveTo(354, 220)
      ..relativeLineTo(18, 18)
      ..relativeLineTo(-18, 18);
    canvas.drawPath(
      arrow,
      Paint()
        ..color = AppColors.brand400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
