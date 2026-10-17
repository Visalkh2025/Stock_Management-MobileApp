import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';

/// Visual style for [AppButton]. All variants share the same height,
/// corner radius, and label weight — only fill/border/text color differ.
enum AppButtonVariant { primary, secondary, text }

/// One button for the whole app. Covers "Sign In" (primary), "Cancel" /
/// "Change password" (secondary/outlined), and inline actions like
/// "Enable 2FA" or "Revoke" (text) — pick a variant instead of writing a
/// new button widget per screen.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  /// Primary/secondary buttons default to filling their row (matches the
  /// full-width Sign In / Save buttons in the mockups). Set false for an
  /// inline action sized to its label (e.g. "Revoke", "Enable 2FA").
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final loadingColor = variant == AppButtonVariant.primary ? Colors.white : AppColors.brand600;

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: loadingColor),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 8)],
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand600,
            disabledBackgroundColor: AppColors.brand600.withValues(alpha: 0.6),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            backgroundColor: AppColors.cardBg,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brand700,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: child,
        ),
    };

    if (!expand) return button;
    return SizedBox(width: double.infinity, height: 48, child: button);
  }
}
