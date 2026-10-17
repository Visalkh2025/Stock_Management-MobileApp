import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// StockFlow brand palette — purple accent scale + semantic status colors.
/// Kept in one place so every screen/widget pulls from the same source
/// instead of hardcoding hex values.
class AppColors {
  AppColors._();

  // Brand (purple) scale — the only accent color family in the app.
  static const brand50 = Color(0xFFF5F3FF);
  static const brand100 = Color(0xFFEDE9FE);
  static const brand300 = Color(0xFFC4B5FD);
  static const brand400 = Color(0xFFA78BFA);
  static const brand600 = Color(0xFF7C3AED);
  static const brand700 = Color(0xFF6D28D9);
  static const brand800 = Color(0xFF5B21B6);
  static const brand900 = Color(0xFF2E1065);

  // Neutrals
  static const ink = Color(0xFF16121F);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFECE9F3);
  static const pageBg = Color(0xFFF1EFF7);
  static const cardBg = Color(0xFFFFFFFF);

  // Third-tier text (least emphasis) — captions, tags, placeholder-ish labels.
  static const textTertiary = Color(0xFF9C99AD);

  // Semantic status colors
  static const success = Color(0xFF16A34A);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFFB45309);
  static const warningBg = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEE2E2);
   static const dangerBg1 = Color(0xFFF8AD9D);
}

/// Poppins (Latin) paired with Noto Sans Khmer as a font-family fallback
/// for any glyph Poppins can't render — Flutter resolves each character
/// against the fallback automatically, so a single Text widget renders
/// English in Poppins and Khmer in Noto Sans Khmer without needing a
/// separate locale-specific theme.
///
/// Noto Sans Khmer over Khmer OS Siemreap/Battambang on purpose: it's
/// published on Google Fonts (fetched the same lazy way as Poppins — no
/// local .ttf assets to bundle), it was drawn as a clean UI sans rather
/// than a calligraphic document font, so it stays legible at small sizes
/// (nav labels, badges, buttons), and its weight range lines up with
/// Poppins' (regular/medium/semibold/bold) for a consistent look across
/// both scripts.
TextStyle _appTextStyle({required FontWeight weight, required double fontSize, required Color color}) {
  return GoogleFonts.poppins(fontWeight: weight, fontSize: fontSize, color: color).copyWith(
    fontFamilyFallback: [GoogleFonts.notoSansKhmer(fontWeight: weight).fontFamily!],
  );
}

/// Builds the app-wide [ThemeData], with the Poppins/Noto Sans Khmer
/// [TextTheme] above and the StockFlow brand colors wired into the
/// [ColorScheme].
ThemeData buildAppTheme() {
  final textTheme = TextTheme(
    displayLarge: _appTextStyle(weight: FontWeight.bold, fontSize: 32, color: AppColors.ink),
    displayMedium: _appTextStyle(weight: FontWeight.bold, fontSize: 28, color: AppColors.ink),
    displaySmall: _appTextStyle(weight: FontWeight.bold, fontSize: 24, color: AppColors.ink),
    headlineLarge: _appTextStyle(weight: FontWeight.bold, fontSize: 20, color: AppColors.ink),
    headlineMedium: _appTextStyle(weight: FontWeight.bold, fontSize: 18, color: AppColors.ink),
    headlineSmall: _appTextStyle(weight: FontWeight.bold, fontSize: 16, color: AppColors.ink),
    titleLarge: _appTextStyle(weight: FontWeight.w600, fontSize: 22, color: AppColors.ink),
    titleMedium: _appTextStyle(weight: FontWeight.w600, fontSize: 18, color: AppColors.ink),
    titleSmall: _appTextStyle(weight: FontWeight.w600, fontSize: 16, color: AppColors.ink),
    bodyLarge: _appTextStyle(weight: FontWeight.w400, fontSize: 16, color: AppColors.ink),
    bodyMedium: _appTextStyle(weight: FontWeight.w400, fontSize: 14, color: AppColors.ink),
    bodySmall: _appTextStyle(weight: FontWeight.w400, fontSize: 12, color: AppColors.muted),
    labelLarge: _appTextStyle(weight: FontWeight.w500, fontSize: 16, color: AppColors.ink),
    labelMedium: _appTextStyle(weight: FontWeight.w500, fontSize: 14, color: AppColors.ink),
    labelSmall: _appTextStyle(weight: FontWeight.w500, fontSize: 12, color: AppColors.muted),
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand700,
    primary: AppColors.brand700,
    onPrimary: Colors.white,
    surface: AppColors.cardBg,
    onSurface: AppColors.ink,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.pageBg,
    colorScheme: colorScheme,
    textTheme: textTheme,
    fontFamily: GoogleFonts.poppins().fontFamily,
    fontFamilyFallback: [GoogleFonts.notoSansKhmer().fontFamily!],
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cardBg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleMedium,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
  );
}
