import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/home_models.dart';

/// One pill-shaped card in a horizontally scrolling row of quick stats —
/// icon tile on the left, title + subtitle on the right.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.data});

  final InsightCardData data;

  @override
  Widget build(BuildContext context) {
    final hasCustomBg = data.cardColor != null;
    return Container(
      constraints: const BoxConstraints(minWidth: 222),
      padding: EdgeInsets.symmetric(horizontal: hasCustomBg ? 18 : 16, vertical: 12),
      decoration: BoxDecoration(
        color: data.cardColor ?? AppColors.cardBg,
        border: hasCustomBg ? null : Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand900.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: data.iconBg, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Icon(data.icon, size: 17, color: data.iconColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 1),
              Text(
                data.subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: data.subtitleColor ?? AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
