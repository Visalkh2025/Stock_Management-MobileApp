import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide language switch (English / Khmer), persisted across restarts.
///
/// Registered as a permanent singleton in `main()` *before* `runApp`, so
/// [locale] already reflects the saved choice by the time [MyApp] builds
/// its first frame — see main.dart. Every other screen reaches it through
/// the same guarded-singleton getter pattern used across this app
/// (e.g. `SettingsController._locale`).
class LocaleController extends GetxController {
  static const _prefsKey = 'app_language_code';

  final locale = const Locale('en', 'US').obs;

  bool get isKhmer => locale.value.languageCode == 'km';

  /// Reads the saved language (if any) and applies it. Awaited in main()
  /// before runApp so there's no flash of the wrong language on launch.
  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'km') {
      locale.value = const Locale('km', 'KH');
    }
  }

  /// Switches the running app's language immediately (via [Get.updateLocale],
  /// which triggers GetX to re-evaluate every `.tr` lookup) and persists the
  /// choice so it survives the next app launch.
  Future<void> changeLocale(String languageCode) async {
    final newLocale = languageCode == 'km' ? const Locale('km', 'KH') : const Locale('en', 'US');
    if (locale.value.languageCode == newLocale.languageCode) return;
    locale.value = newLocale;
    Get.updateLocale(newLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, languageCode);
  }
}
