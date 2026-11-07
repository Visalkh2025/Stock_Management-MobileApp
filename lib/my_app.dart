import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/localization/app_translations.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/locale_controller.dart';
import 'package:stock_management/Controller/theme_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute = Routes.splash});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    // Registered (and loaded) in main() before runApp — already available.
    final startingLocale = Get.find<LocaleController>().locale.value;
    return GetMaterialApp(
      title: 'Stock',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(dark: true),
      themeMode: Get.find<ThemeController>().mode.value,
      translations: AppTranslations(),
      locale: startingLocale,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: initialRoute,
      getPages: Routes.pages,
    );
  }
}
