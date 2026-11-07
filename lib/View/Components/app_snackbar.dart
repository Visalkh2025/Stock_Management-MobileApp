import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';

/// What a message means — decides the color and icon.
enum SnackKind { success, error, warning, info }

/// The one snackbar of the app.
class AppSnackbar {
  const AppSnackbar._();

  static void success(String title, String message) => show(SnackKind.success, title, message);
  static void error(String title, String message) => show(SnackKind.error, title, message);
  static void warning(String title, String message) => show(SnackKind.warning, title, message);
  static void info(String title, String message) => show(SnackKind.info, title, message);

  static void show(SnackKind kind, String title, String message) {
    final style = _StyleOf.of(kind);
    // Replace the one on screen instead of queueing messages behind it.
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

    Get.showSnackbar(
      GetSnackBar(
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: style.background,
        borderRadius: 16,
        borderColor: style.color.withAlpha(90),
        borderWidth: 1,
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        boxShadows: [
          BoxShadow(
            color: style.color.withAlpha(50),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
        duration: Duration(milliseconds: kind == SnackKind.error ? 2500 : 1800),
        animationDuration: const Duration(milliseconds: 350),
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInCubic,
        isDismissible: true,
        onTap: (_) => Get.closeCurrentSnackbar(),
        // Icon is part of the message row so it lines up with the title.
        messageText: Material(
          type: MaterialType.transparency,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: style.color, shape: BoxShape.circle),
                child: Icon(style.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (message.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        message,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleOf {
  const _StyleOf(this.color, this.background, this.icon);

  final Color color;
  final Color background;
  final IconData icon;

  static _StyleOf of(SnackKind kind) {
    switch (kind) {
      case SnackKind.success:
        return _StyleOf(AppColors.success, AppColors.successBg, Icons.check_rounded);
      case SnackKind.error:
        return _StyleOf(AppColors.danger, AppColors.dangerBg, Icons.close_rounded);
      case SnackKind.warning:
        return _StyleOf(AppColors.warning, AppColors.warningBg, Icons.priority_high_rounded);
      case SnackKind.info:
        return _StyleOf(AppColors.brand700, AppColors.brand50, Icons.info_outline_rounded);
    }
  }
}
