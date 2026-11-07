import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One complete set of the theme-dependent colors. [AppColors] hands out the
/// light or the dark one depending on [AppColors.isDark].
class AppPalette {
  const AppPalette({
    required this.ink,
    required this.muted,
    required this.border,
    required this.pageBg,
    required this.cardBg,
    required this.textTertiary,
    required this.brand50,
    required this.brand100,
    required this.brand700,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.danger,
    required this.dangerBg,
    required this.dangerBg1,
  });

  final Color ink;
  final Color muted;
  final Color border;
  final Color pageBg;
  final Color cardBg;
  final Color textTertiary;
  final Color brand50;
  final Color brand100;
  final Color brand700;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color danger;
  final Color dangerBg;
  final Color dangerBg1;
}

const AppPalette _lightPalette = AppPalette(
  ink: Color(0xFF16121F),
  muted: Color(0xFF6B7280),
  border: Color(0xFFECE9F3),
  pageBg: Color(0xFFF1EFF7),
  cardBg: Color(0xFFFFFFFF),
  textTertiary: Color(0xFF9C99AD),
  brand50: Color(0xFFF5F3FF),
  brand100: Color(0xFFEDE9FE),
  brand700: Color(0xFF6D28D9),
  success: Color(0xFF16A34A),
  successBg: Color(0xFFDCFCE7),
  warning: Color(0xFFB45309),
  warningBg: Color(0xFFFEF3C7),
  danger: Color(0xFFDC2626),
  dangerBg: Color(0xFFFEE2E2),
  dangerBg1: Color(0xFFF8AD9D),
);

// StockFlow dark tokens: bg #0F0D16, card #1C1826, text #F3F2FA, muted #9C99AD,
// brighter accent #8B5CF6; status tints are deep, desaturated versions.
const AppPalette _darkPalette = AppPalette(
  ink: Color(0xFFF3F2FA),
  muted: Color(0xFF9C99AD),
  border: Color(0xFF2B2738),
  pageBg: Color(0xFF0F0D16),
  cardBg: Color(0xFF1C1826),
  textTertiary: Color(0xFF7D7A90),
  brand50: Color(0xFF2A2145),
  brand100: Color(0xFF362A5C),
  brand700: Color(0xFF8B5CF6),
  success: Color(0xFF22C55E),
  successBg: Color(0xFF12301F),
  warning: Color(0xFFF59E0B),
  warningBg: Color(0xFF3A2C0E),
  danger: Color(0xFFEF4444),
  dangerBg: Color(0xFF3B1A1E),
  dangerBg1: Color(0xFFB4413A),
);

class AppColors {
  AppColors._();

  /// Set by ThemeController (before the first frame, and whenever the user or
  /// the system switches theme). Every theme-dependent color below reads it,
  /// so they are getters — not `const` — and can't be used in const contexts.
  static bool isDark = false;

  static AppPalette get palette => isDark ? _darkPalette : _lightPalette;

  // Brand (purple) scale — the only accent color family in the app.
  static Color get brand50 => palette.brand50;
  static Color get brand100 => palette.brand100;
  static const brand300 = Color(0xFFC4B5FD);
  static const brand400 = Color(0xFFA78BFA);
  static const brand600 = Color(0xFF7C3AED);
  static Color get brand700 => palette.brand700;
  static const brand800 = Color(0xFF5B21B6);
  static const brand900 = Color(0xFF2E1065);

  // Neutrals
  static Color get ink => palette.ink;
  static Color get muted => palette.muted;
  static Color get border => palette.border;
  static Color get pageBg => palette.pageBg;
  static Color get cardBg => palette.cardBg;

  // Third-tier text (least emphasis) — captions, tags, placeholder-ish labels.
  static Color get textTertiary => palette.textTertiary;

  // Semantic status colors
  static Color get success => palette.success;
  static Color get successBg => palette.successBg;
  static Color get warning => palette.warning;
  static Color get warningBg => palette.warningBg;
  static Color get danger => palette.danger;
  static Color get dangerBg => palette.dangerBg;
  static Color get dangerBg1 => palette.dangerBg1;
}

TextStyle _appTextStyle({required FontWeight weight, required double fontSize, required Color color}) {
  return GoogleFonts.poppins(fontWeight: weight, fontSize: fontSize, color: color).copyWith(
    fontFamilyFallback: [GoogleFonts.notoSansKhmer(fontWeight: weight).fontFamily!],
  );
}

/// Builds the app-wide [ThemeData], with the Poppins/Noto Sans Khmer
/// [TextTheme] above and the StockFlow brand colors wired into the
/// [ColorScheme]. [dark] picks the dark palette.
ThemeData buildAppTheme({bool dark = false}) {
  final p = dark ? _darkPalette : _lightPalette;
  final textTheme = TextTheme(
    displayLarge: _appTextStyle(weight: FontWeight.bold, fontSize: 32, color: p.ink),
    displayMedium: _appTextStyle(weight: FontWeight.bold, fontSize: 28, color: p.ink),
    displaySmall: _appTextStyle(weight: FontWeight.bold, fontSize: 24, color: p.ink),
    headlineLarge: _appTextStyle(weight: FontWeight.bold, fontSize: 20, color: p.ink),
    headlineMedium: _appTextStyle(weight: FontWeight.bold, fontSize: 18, color: p.ink),
    headlineSmall: _appTextStyle(weight: FontWeight.bold, fontSize: 16, color: p.ink),
    titleLarge: _appTextStyle(weight: FontWeight.w600, fontSize: 22, color: p.ink),
    titleMedium: _appTextStyle(weight: FontWeight.w600, fontSize: 18, color: p.ink),
    titleSmall: _appTextStyle(weight: FontWeight.w600, fontSize: 16, color: p.ink),
    bodyLarge: _appTextStyle(weight: FontWeight.w400, fontSize: 16, color: p.ink),
    bodyMedium: _appTextStyle(weight: FontWeight.w400, fontSize: 14, color: p.ink),
    bodySmall: _appTextStyle(weight: FontWeight.w400, fontSize: 12, color: p.muted),
    labelLarge: _appTextStyle(weight: FontWeight.w500, fontSize: 16, color: p.ink),
    labelMedium: _appTextStyle(weight: FontWeight.w500, fontSize: 14, color: p.ink),
    labelSmall: _appTextStyle(weight: FontWeight.w500, fontSize: 12, color: p.muted),
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: _lightPalette.brand700,
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: p.brand700,
    onPrimary: Colors.white,
    surface: p.cardBg,
    onSurface: p.ink,
    error: p.danger,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: p.pageBg,
    colorScheme: colorScheme,
    textTheme: textTheme,
    fontFamily: GoogleFonts.poppins().fontFamily,
    fontFamilyFallback: [GoogleFonts.notoSansKhmer().fontFamily!],
    appBarTheme: AppBarTheme(
      backgroundColor: p.cardBg,
      foregroundColor: p.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleMedium,
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1),
  );

  if (!dark) return base;

  // Dark: M3 would otherwise derive dialog / sheet / menu surfaces from the
  // seed colour (a purplish grey) — pin them to the card colour instead.
  return base.copyWith(
    canvasColor: p.cardBg,
    cardColor: p.cardBg,
    dialogTheme: DialogThemeData(backgroundColor: p.cardBg, surfaceTintColor: Colors.transparent),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.cardBg,
      modalBackgroundColor: p.cardBg,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(color: p.cardBg, surfaceTintColor: Colors.transparent),
    datePickerTheme: DatePickerThemeData(backgroundColor: p.cardBg, surfaceTintColor: Colors.transparent),
  );
}
