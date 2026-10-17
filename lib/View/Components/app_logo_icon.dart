import 'package:flutter/material.dart';

/// The StockFlow box/cube mark, drawn as pure vector strokes.
///
/// Kept as a `CustomPainter` (instead of a bundled PNG/SVG) so it renders
/// pixel-crisp at any size and on any pixel density with zero asset
/// management — just drop it wherever the brand mark is needed and tint it
/// with [color].
class AppLogoIcon extends StatelessWidget {
  const AppLogoIcon({
    super.key,
    this.size = 28,
    this.color = const Color(0xFFF3F2FA),
    this.strokeWidth = 1.8,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BoxIconPainter(color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _BoxIconPainter extends CustomPainter {
  const _BoxIconPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  // Original design is on a 24x24 viewBox — scale every point to the
  // widget's actual size so the mark stays sharp at any resolution.
  static const double _viewBox = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _viewBox;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Offset p(double x, double y) => Offset(x * scale, y * scale);

    final outline = Path()
      ..moveTo(p(12, 2).dx, p(12, 2).dy)
      ..lineTo(p(21, 7).dx, p(21, 7).dy)
      ..lineTo(p(21, 17).dx, p(21, 17).dy)
      ..lineTo(p(12, 22).dx, p(12, 22).dy)
      ..lineTo(p(3, 17).dx, p(3, 17).dy)
      ..lineTo(p(3, 7).dx, p(3, 7).dy)
      ..close();

    final topCross = Path()
      ..moveTo(p(3, 7).dx, p(3, 7).dy)
      ..lineTo(p(12, 12).dx, p(12, 12).dy)
      ..lineTo(p(21, 7).dx, p(21, 7).dy);

    final centerStem = Path()
      ..moveTo(p(12, 12).dx, p(12, 12).dy)
      ..lineTo(p(12, 22).dx, p(12, 22).dy);

    canvas.drawPath(outline, paint);
    canvas.drawPath(topCross, paint);
    canvas.drawPath(centerStem, paint);
  }

  @override
  bool shouldRepaint(covariant _BoxIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
