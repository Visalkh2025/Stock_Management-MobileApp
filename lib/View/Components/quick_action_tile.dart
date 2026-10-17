import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/home_models.dart';

/// One tile in the 4-column Quick Actions grid — icon over label, a single
/// brand-purple tint on white (no per-tile colors).
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({super.key, required this.data});

  final QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand900.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: data.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(data.icon, size: 19, color: AppColors.brand700),
                const SizedBox(height: 7),
                Text(
                  data.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.brand700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
