import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/locale_controller.dart';
import 'package:stock_management/Controller/theme_controller.dart';
import 'package:stock_management/Services/push_service.dart';
import 'package:stock_management/my_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = Get.put(LocaleController(), permanent: true);
  await localeController.loadSaved();
  final themeController = Get.put(ThemeController(), permanent: true);
  await themeController.loadSaved();
  // Firebase for push notifications — silently skipped if not configured.
  await PushService.instance.init();
  // Always start on the splash screen: it plays the intro and, meanwhile,
  // decides between Home (login still valid) and Login — see SplashController.
  runApp(const MyApp(initialRoute: Routes.splash));
}
