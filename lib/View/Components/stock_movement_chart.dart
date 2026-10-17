import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';

/// Small two-line (in/out) trend chart used on the Home screen's
/// "Stock movement" card. Values are 0..1 (fraction of the chart height,
/// 1 = top, 0 = bottom) so any series length/range can be plotted.
class StockMovementChart extends StatelessWidget {
  const StockMovementChart({
    super.key,
    required this.inSeries,
    required this.outSeries,
    this.height = 86,
  });

  final List<double> inSeries;
  final List<double> outSeries;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _ChartPainter(inSeries: inSeries, outSeries: outSeries),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.inSeries, required this.outSeries});

  final List<double> inSeries;
  final List<double> outSeries;

  Offset _pointAt(List<double> series, int index, Size size) {
    final dx = series.length > 1 ? size.width * index / (series.length - 1) : 0.0;
    final dy = size.height * (1 - series[index].clamp(0.0, 1.0));
    return Offset(dx, dy);
  }

  Path _pathFor(List<double> series, Size size) {
    final path = Path();
    for (var i = 0; i < series.length; i++) {
      final point = _pointAt(series, i, size);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  Path _dashedPath(Path source) {
    const dashWidth = 4.0;
    const dashGap = 4.0;
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        dashed.addPath(metric.extractPath(distance, next), Offset.zero);
        distance = next + dashGap;
      }
    }
    return dashed;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (outSeries.isNotEmpty) {
      final outPaint = Paint()
        ..color = const Color(0xFF9CA3AF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(_dashedPath(_pathFor(outSeries, size)), outPaint);
    }

    if (inSeries.isNotEmpty) {
      final inPaint = Paint()
        ..color = AppColors.brand600
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(_pathFor(inSeries, size), inPaint);

      var peakIndex = 0;
      for (var i = 1; i < inSeries.length; i++) {
        if (inSeries[i] > inSeries[peakIndex]) peakIndex = i;
      }
      final peakPoint = _pointAt(inSeries, peakIndex, size);
      canvas.drawCircle(peakPoint, 4, Paint()..color = AppColors.brand600);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.inSeries != inSeries || oldDelegate.outSeries != outSeries;
  }
}
