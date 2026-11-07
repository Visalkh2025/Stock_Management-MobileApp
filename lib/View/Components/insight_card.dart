import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/home_models.dart';

/// One KPI tile on Home: icon, big number, small label.
class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.data});

  final KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.brand900.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: data.iconBg, borderRadius: BorderRadius.circular(13)),
            alignment: Alignment.center,
            child: Icon(data.icon, size: 19, color: data.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.15,
                    ),
                  ),
                ),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
