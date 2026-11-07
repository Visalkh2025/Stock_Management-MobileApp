import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/purchase_order_models.dart';

/// Colour of a fill level: green below 90%, amber from 90%, red when over.
({Color color, Color background}) capacityColors(double ratio) {
  if (ratio > 1) return (color: AppColors.danger, background: AppColors.dangerBg);
  if (ratio >= 0.9) return (color: AppColors.warning, background: AppColors.warningBg);
  return (color: AppColors.success, background: AppColors.successBg);
}

/// "120 / 500 units" with a fill bar — how full a warehouse is. With no
/// limit it just shows how many units are in stock.
class WarehouseUsageBar extends StatelessWidget {
  const WarehouseUsageBar({super.key, required this.used, required this.capacity, this.incoming = 0});

  final double used;

  /// Null = no limit.
  final double? capacity;

  /// Still to arrive on open purchase orders.
  final double incoming;

  @override
  Widget build(BuildContext context) {
    final cap = capacity;
    if (cap == null || cap <= 0) {
      return Text(
        'wh_usage_nolimit'.trParams({'used': formatQty(used)}),
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
      );
    }
    final ratio = used / cap;
    final colors = capacityColors(ratio);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'wh_usage'.trParams({'used': formatQty(used), 'cap': formatQty(cap)}),
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(8)),
              child: Text(
                '${(ratio * 100).round()}%',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: colors.color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: AppColors.pageBg,
            valueColor: AlwaysStoppedAnimation(colors.color),
          ),
        ),
        if (incoming > 0) ...[
          const SizedBox(height: 5),
          Text(
            'wh_on_order'.trParams({'n': formatQty(incoming)}),
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
          ),
        ],
      ],
    );
  }
}

/// Tells how full the warehouse gets if this purchase order goes through.
/// [onlyWarnings] hides the "plenty of room" message (used on the order page).
class CapacityBanner extends StatelessWidget {
  const CapacityBanner({
    super.key,
    required this.info,
    required this.warehouseName,
    this.onlyWarnings = false,
    this.messagePrefix = 'po_capacity',
  });

  final WarehouseCapacity info;
  final String warehouseName;
  final bool onlyWarnings;

  /// Translation keys are `<prefix>_over`, `<prefix>_nearly` and `<prefix>_ok`
  /// (purchase orders say "this order", stock forms say "this stock").
  final String messagePrefix;

  @override
  Widget build(BuildContext context) {
    if (!info.hasLimit) return const SizedBox.shrink();
    if (onlyWarnings && !info.isOver && !info.isNearlyFull) return const SizedBox.shrink();

    final capacity = info.capacity!;
    final String text;
    final Color color;
    final Color background;
    final IconData icon;
    if (info.isOver) {
      color = AppColors.danger;
      background = AppColors.dangerBg;
      icon = Icons.error_outline_rounded;
      text = '${messagePrefix}_over'.trParams({
        'warehouse': warehouseName,
        'projected': formatQty(info.projected),
        'cap': formatQty(capacity),
        'over': formatQty(info.projected - capacity),
      });
    } else if (info.isNearlyFull) {
      color = AppColors.warning;
      background = AppColors.warningBg;
      icon = Icons.warning_amber_rounded;
      text = '${messagePrefix}_nearly'.trParams({
        'warehouse': warehouseName,
        'percent': (info.percentAfter ?? 0).toStringAsFixed(0),
        'free': formatQty(info.freeAfter ?? 0),
      });
    } else {
      color = AppColors.success;
      background = AppColors.successBg;
      icon = Icons.check_circle_outline_rounded;
      text = '${messagePrefix}_ok'.trParams({
        'warehouse': warehouseName,
        'percent': (info.percentAfter ?? 0).toStringAsFixed(0),
        'free': formatQty(info.freeAfter ?? 0),
      });
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
