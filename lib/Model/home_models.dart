import 'package:flutter/material.dart';

/// One pill card in the horizontally-scrolling insight row at the top of
/// the Home screen (e.g. "Reorder needed", "Units in").
class InsightCardData {
  const InsightCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBg,
    this.cardColor,
    this.subtitleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBg;

  /// Null falls back to the default card fill (white + border).
  final Color? cardColor;

  /// Null falls back to the default muted subtitle color.
  final Color? subtitleColor;
}

/// One tile in the 4-column Quick Actions grid.
class QuickActionData {
  const QuickActionData({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

enum TransactionKind { received, transfer, alert }

/// One row in the Recent Transactions list.
class TransactionData {
  const TransactionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.tagLabel,
    required this.kind,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amountLabel;
  final String tagLabel;
  final TransactionKind kind;
}
