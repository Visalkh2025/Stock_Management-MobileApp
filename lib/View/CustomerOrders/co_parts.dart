import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/customer_order_models.dart';

class CoStatusBadge extends StatelessWidget {
  const CoStatusBadge(this.status, {super.key});

  final CoStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: status.background, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.labelKey.tr,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: status.color),
      ),
    );
  }
}

/// "Paid" / "Unpaid" pill.
class CoPaidBadge extends StatelessWidget {
  const CoPaidBadge(this.paid, {super.key});

  final bool paid;

  @override
  Widget build(BuildContext context) {
    final color = paid ? AppColors.success : AppColors.warning;
    final bg = paid ? AppColors.successBg : AppColors.warningBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        (paid ? 'co_paid' : 'co_unpaid').tr,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
