import 'package:flutter/material.dart';

/// Shared decorative background for the Auth flow (Login, Forgot Password,
/// Verify OTP, New Password): a deep-purple gradient with soft color glows
/// and a faint dot-grid texture.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E1065), Color(0xFF1A0B3D)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _Glow(alignment: Alignment(-0.7, -0.8), color: Color(0xFFF472B6), size: 260),
          const _Glow(alignment: Alignment(0.9, 0.6), color: Color(0xFF60A5FA), size: 280),
          const _Glow(alignment: Alignment(0.0, 1.1), color: Color(0xFFA78BFA), size: 320),
          CustomPaint(painter: _DotGridPainter(), size: Size.infinite),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.alignment, required this.color, required this.size});

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  static const _spacing = 22.0;
  static const _dotRadius = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    for (double y = 0; y < size.height; y += _spacing) {
      for (double x = 0; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}
