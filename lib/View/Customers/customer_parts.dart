import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/customer_models.dart';

class CustomerStatusBadge extends StatelessWidget {
  const CustomerStatusBadge(this.status, {super.key});

  final CustomerStatus status;

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

/// Loyalty tier as a small outlined chip.
class CustomerTierChip extends StatelessWidget {
  const CustomerTierChip(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.brand700),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(name, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.brand700)),
    );
  }
}
