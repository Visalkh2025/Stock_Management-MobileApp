import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/home_models.dart';

/// One row in the Recent Transactions list — icon tile, title/subtitle,
/// and a right-aligned amount + tag, colored by [TransactionKind].
class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key, required this.data});

  final TransactionData data;

  Color get _accentColor {
    switch (data.kind) {
      case TransactionKind.received:
        return AppColors.success;
      case TransactionKind.transfer:
        return AppColors.brand700;
      case TransactionKind.alert:
        return AppColors.warning;
    }
  }

  Color get _amountColor {
    return data.kind == TransactionKind.transfer ? AppColors.ink : _accentColor;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand900.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(data.icon, size: 17, color: _accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                data.subtitle,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.amountLabel,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _amountColor),
            ),
            Text(
              data.tagLabel,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
            ),
          ],
        ),
      ],
    );
  }
}
