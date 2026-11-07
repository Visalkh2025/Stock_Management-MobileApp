import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/home_models.dart';

/// Home donut: how the units in stock are split by category or by product.
class BreakdownCard extends StatelessWidget {
  const BreakdownCard({
    super.key,
    required this.slices,
    required this.totalLabel,
    required this.mode,
    required this.onModeChanged,
  });

  final List<ChartSlice> slices;

  /// Formatted total units shown in the donut hole.
  final String totalLabel;

  /// 'category' | 'product'
  final String mode;
  final ValueChanged<String> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.brand900.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'home_breakdown_title'.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              _toggle(),
            ],
          ),
          const SizedBox(height: 16),
          if (slices.isEmpty || total <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'home_breakdown_empty'.tr,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 136,
                  height: 136,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(size: const Size.square(136), painter: _DonutPainter(slices, total)),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            totalLabel,
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                          Text(
                            'home_breakdown_units'.tr,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      for (final s in slices) _legendRow(s, total),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _legendRow(ChartSlice s, double total) {
    final pct = s.value / total * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${pct.round()}%',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _toggle() {
    Widget seg(String value, String label) {
      final on = mode == value;
      return GestureDetector(
        onTap: () => onModeChanged(value),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: on ? AppColors.brand700 : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: on ? Colors.white : AppColors.muted),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('category', 'home_breakdown_category'.tr),
          seg('product', 'home_breakdown_product'.tr),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.total);

  final List<ChartSlice> slices;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 20.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final gap = slices.length > 1 ? 0.035 : 0.0;
    var start = -math.pi / 2;
    for (final s in slices) {
      final sweep = s.value / total * 2 * math.pi;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawArc(rect, start + gap / 2, math.max(sweep - gap, 0.001), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.slices != slices || old.total != total;
}
