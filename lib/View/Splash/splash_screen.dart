import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/splash_controller.dart';

/// Opening screen. The StockFlow shelf builds itself: the frame rises, the shelves slide in, boxes drop onto them one by one (bottom row first), the arrow draws itself, then the name fades in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  /// Whole intro. The last ~10% is a short hold so the finished logo is seen.
  static const _duration = Duration(milliseconds: 2800);

  late final AnimationController _anim = AnimationController(vsync: this, duration: _duration);

  /// True when the intro is over but the sign-in check is still running
  /// (slow network) — shows a small spinner.
  final _waiting = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    var resolved = false;
    final routeFuture = SplashController.resolveRoute().whenComplete(() => resolved = true);
    try {
      await _anim.forward();
    } catch (_) {
      // Screen closed early: nothing left to do.
      return;
    }
    if (!mounted) return;
    if (!resolved) _waiting.value = true;
    final route = await routeFuture;
    if (!mounted) return;
    Get.offAllNamed(route);
  }

  @override
  void dispose() {
    _anim.dispose();
    _waiting.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    final anim = _anim;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
            ),
          ),
          child: Stack(
            children: [
              // Soft light behind the logo.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.25),
                      radius: 0.75,
                      colors: [Colors.white.withAlpha(46), Colors.white.withAlpha(0)],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 210,
                      height: 210 * 310 / 304,
                      child: CustomPaint(painter: _ShelfBuildPainter(anim)),
                    ),
                    const SizedBox(height: 30),
                    AnimatedBuilder(
                      animation: anim,
                      builder: (_, _) {
                        final name = _seg(anim.value, 0.68, 0.86, Curves.easeOutCubic);
                        final khmer = _seg(anim.value, 0.75, 0.93, Curves.easeOutCubic);
                        return Column(
                          children: [
                            Opacity(
                              opacity: name,
                              child: Transform.translate(
                                offset: Offset(0, (1 - name) * 16),
                                child: Text(
                                  'StockFlow',
                                  style: textStyle.copyWith(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Opacity(
                              opacity: khmer,
                              child: Transform.translate(
                                offset: Offset(0, (1 - khmer) * 16),
                                child: Text(
                                  'ស្ដុក',
                                  style: textStyle.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brand300,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Only when the network is slow and the intro is already over.
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.paddingOf(context).bottom + 48,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _waiting,
                  builder: (_, waiting, _) => AnimatedOpacity(
                    opacity: waiting ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 0 before [from], 1 after [to], eased in between.
double _seg(double t, double from, double to, [Curve curve = Curves.linear]) {
  if (t <= from) return 0;
  if (t >= to) return 1;
  return curve.transform((t - from) / (to - from));
}

class _Box {
  const _Box(this.x, this.y, this.w, this.h, {this.accent = false, this.tape = false});

  final double x, y, w, h;
  final bool accent;
  final bool tape;
}

/// The logo shelf in its 304 x 310 design box, drawn for animation time `t`
/// (0..1 of the whole intro). Same shapes as the app icon.
class _ShelfBuildPainter extends CustomPainter {
  _ShelfBuildPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  // Bottom shelf first: stock is put in from the floor up.
  static const _boxes = <_Box>[
    _Box(140, 324, 96, 64, tape: true),
    _Box(250, 338, 50, 50, accent: true),
    _Box(140, 236, 56, 52, accent: true),
    _Box(212, 216, 84, 72, tape: true),
    _Box(140, 124, 74, 64, tape: true),
    _Box(228, 144, 54, 44, accent: true),
    _Box(300, 132, 64, 56),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    canvas.save();
    canvas.scale(size.width / 304);
    canvas.translate(-104, -104);

    RRect rr(double l, double top, double r, double b, double rad) =>
        RRect.fromLTRBR(l, top, r, b, Radius.circular(rad));

    // Floor shadow fades in with the frame.
    final shadow = _seg(t, 0, 0.25, Curves.easeOut);
    canvas.drawOval(
      const Rect.fromLTWH(120, 404, 272, 18),
      Paint()
        ..color = Colors.black.withAlpha((38 * shadow).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final white = Paint()..color = Colors.white;

    // 1. Posts rise from the floor.
    final rise = _seg(t, 0, 0.22, Curves.easeOutCubic);
    if (rise > 0) {
      final top = 414 - 310 * rise;
      canvas.drawRRect(rr(104, top, 120, 414, 8), white);
      canvas.drawRRect(rr(392, top, 408, 414, 8), white);
    }

    // 2. Shelves slide in from the left, bottom one first.
    const shelfY = [388.0, 288.0, 188.0];
    for (var i = 0; i < shelfY.length; i++) {
      final p = _seg(t, 0.08 + i * 0.04, 0.24 + i * 0.04, Curves.easeOutCubic);
      if (p > 0) canvas.drawRRect(rr(104, shelfY[i], 104 + 304 * p, shelfY[i] + 14, 7), white);
    }

    // 3. Boxes drop in and bounce once.
    for (var i = 0; i < _boxes.length; i++) {
      final b = _boxes[i];
      final start = 0.22 + i * 0.05;
      final end = start + 0.15;
      if (t <= start) continue;
      final drop = _seg(t, start, end, Curves.bounceOut);
      final fade = _seg(t, start, start + 0.04);
      final dy = -(1 - drop) * 240;
      final color = (b.accent ? const Color(0xFFC4B5FD) : Colors.white).withAlpha((255 * fade).round());
      canvas.drawRRect(rr(b.x, b.y + dy, b.x + b.w, b.y + dy + b.h, 12), Paint()..color = color);
      if (b.tape) {
        canvas.drawRRect(
          rr(b.x + b.w / 2 - 4, b.y + dy, b.x + b.w / 2 + 4, b.y + dy + b.h * 0.42, 4),
          Paint()..color = const Color(0xFF5B21B6).withAlpha((64 * fade).round()),
        );
      }
    }

    // 4. The arrow draws itself on the middle shelf: stock is on the move.
    final arrowP = _seg(t, 0.66, 0.78, Curves.easeOutCubic);
    if (arrowP > 0) {
      final path = Path()
        ..moveTo(322, 238)
        ..relativeLineTo(50, 0)
        ..moveTo(354, 220)
        ..relativeLineTo(18, 18)
        ..relativeLineTo(-18, 18);
      final paint = Paint()
        ..color = const Color(0xFFDDD6FE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final shaft = path.computeMetrics().first;
      canvas.drawPath(shaft.extractPath(0, shaft.length * arrowP), paint);
      final head = path.computeMetrics().last;
      final headP = _seg(arrowP, 0.5, 1);
      canvas.drawPath(head.extractPath(0, head.length * headP), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShelfBuildPainter oldDelegate) => oldDelegate.animation != animation;
}
