import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/localization/app_translations.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/locale_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Registered (and loaded) in main() before runApp — already available.
    final startingLocale = Get.find<LocaleController>().locale.value;
    return GetMaterialApp(
      title: 'StockFlow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      translations: AppTranslations(),
      locale: startingLocale,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: Routes.login,
      getPages: Routes.pages,
    );
  }
}
