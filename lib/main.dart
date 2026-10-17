import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/locale_controller.dart';
import 'package:stock_management/my_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = Get.put(LocaleController(), permanent: true);
  await localeController.loadSaved();
  runApp(const MyApp());
}
