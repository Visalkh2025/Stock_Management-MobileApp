import 'package:flutter/material.dart';

/// One KPI card in the 2×2 grid at the top of the Home screen.
class KpiData {
  const KpiData({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBg,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBg;
}

/// One slice of the Home donut chart (a category or a product).
class ChartSlice {
  const ChartSlice({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;
}

/// One tile in the 4-column Quick Actions grid.
class QuickActionData {
  const QuickActionData({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}
