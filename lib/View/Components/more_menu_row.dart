import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';

/// One tappable row inside a More-screen menu group — icon tile, label,
/// and an optional trailing widget (a caption, a count badge, a chevron).
class MoreMenuRow extends StatelessWidget {
  const MoreMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor = AppColors.brand700,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(11)),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
