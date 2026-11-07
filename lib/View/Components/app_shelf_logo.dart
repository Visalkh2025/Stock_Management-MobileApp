import 'package:flutter/material.dart';

/// The StockFlow logo: the shelf with boxes on a rounded purple tile — the
/// same picture as the app icon, drawn as vectors so it is sharp at any size.
/// Use [size] for the width/height of the whole tile.
class AppShelfLogo extends StatelessWidget {
  const AppShelfLogo({super.key, this.size = 72, this.shadow = true});

  final double size;

  /// Soft drop shadow under the tile.
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: shadow
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: size * 0.6, offset: Offset(0, size * 0.25))]
            : null,
      ),
      child: CustomPaint(painter: _ShelfLogoPainter()),
    );
  }
}

class _ShelfLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final tile = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.26));
    canvas.drawRRect(
      tile,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
        ).createShader(rect),
    );

    // The shelf is a 304 x 310 drawing; make it ~64% of the tile, centered.
    final scale = size.width * 0.64 / 304;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-256, -259);

    RRect r(double x, double y, double w, double h, double rad) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(rad));

    final white = Paint()..color = Colors.white;
    canvas.drawRRect(r(104, 104, 16, 310, 8), white);
    canvas.drawRRect(r(392, 104, 16, 310, 8), white);
    canvas.drawRRect(r(104, 188, 304, 14, 7), white);
    canvas.drawRRect(r(104, 288, 304, 14, 7), white);
    canvas.drawRRect(r(104, 388, 304, 14, 7), white);

    const accent = Color(0xFFC4B5FD);
    void box(double x, double y, double w, double h, {bool accentColor = false, bool tape = false}) {
      canvas.drawRRect(r(x, y, w, h, 12), Paint()..color = accentColor ? accent : Colors.white);
      if (tape) {
        canvas.drawRRect(
          r(x + w / 2 - 4, y, 8, h * 0.42, 4),
          Paint()..color = const Color(0xFF5B21B6).withValues(alpha: 0.25),
        );
      }
    }

    box(140, 124, 74, 64, tape: true);
    box(228, 144, 54, 44, accentColor: true);
    box(300, 132, 64, 56);
    box(140, 236, 56, 52, accentColor: true);
    box(212, 216, 84, 72, tape: true);
    box(140, 324, 96, 64, tape: true);
    box(250, 338, 50, 50);

    final arrow = Path()
      ..moveTo(322, 238)
      ..relativeLineTo(50, 0)
      ..moveTo(354, 220)
      ..relativeLineTo(18, 18)
      ..relativeLineTo(-18, 18);
    canvas.drawPath(
      arrow,
      Paint()
        ..color = const Color(0xFFDDD6FE)
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
