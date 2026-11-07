import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/api_config.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/customer_orders_controller.dart';
import 'package:stock_management/Controller/home_controller.dart';
import 'package:stock_management/Controller/notifications_controller.dart';
import 'package:stock_management/Services/api_client.dart';

/// Push notifications for staff (Firebase Cloud Messaging, Android).
///
/// Everything here is best-effort: if Firebase is not configured (no
/// `android/app/google-services.json`) or the phone has no Google Play
/// services, the app simply runs without push.
///
/// Flow: [init] at app start -> [start] once a staff member is signed in
/// (registers the phone's token with `POST /devices`) -> the backend pushes
/// "New customer order" -> tapping it opens that order -> [unregister] on
/// sign-out so the phone stops receiving this person's alerts.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _api = ApiClient();
  bool _ready = false;
  bool _listening = false;
  String? _token;

  /// Call once from `main()`. Never throws.
  Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await Firebase.initializeApp();
      _ready = true;
    } catch (e) {
      debugPrint('Push disabled (Firebase not configured): $e');
    }
  }

  /// Call after sign-in (also when a saved session is restored).
  Future<void> start() async {
    if (!_ready) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      await _register(await messaging.getToken());

      if (!_listening) {
        _listening = true;
        messaging.onTokenRefresh.listen(_register);
        FirebaseMessaging.onMessage.listen(_onForeground);
        FirebaseMessaging.onMessageOpenedApp.listen(_open);
      }

      // App was closed and opened by tapping a notification.
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        Future.delayed(const Duration(milliseconds: 700), () => _open(initial));
      }
    } catch (e) {
      debugPrint('Push start failed: $e');
    }
  }

  /// Call BEFORE the session is cleared on sign-out (needs the access token).
  Future<void> unregister() async {
    if (!_ready) return;
    try {
      final token = _token ?? await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _api.post(ApiConfig.devicesUnregister, body: {'token': token});
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Push unregister failed: $e');
    }
    _token = null;
  }

  Future<void> _register(String? token) async {
    if (token == null || token.isEmpty) return;
    _token = token;
    // Debug builds only: lets you send a test message from the Firebase console.
    if (kDebugMode) debugPrint('Push: FCM token = $token');
    try {
      await _api.post(ApiConfig.devices, body: {'token': token, 'platform': 'android'});
      debugPrint('Push: phone registered with the server.');
    } catch (e) {
      debugPrint('Push token registration failed: $e');
    }
  }

  /// App is open: the system shows nothing, so show a tappable banner and
  /// refresh the Customer Orders list if it is on screen.
  void _onForeground(RemoteMessage message) {
    if (Get.isRegistered<CustomerOrdersController>()) {
      Get.find<CustomerOrdersController>().load();
    }
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().refreshNotifications();
    }
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().load();
    }
    final n = message.notification;
    if (n == null) return;
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.showSnackbar(
      GetSnackBar(
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.cardBg,
        borderRadius: 16,
        borderColor: AppColors.brand700.withAlpha(90),
        borderWidth: 1,
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        duration: const Duration(seconds: 5),
        isDismissible: true,
        onTap: (_) {
          Get.closeCurrentSnackbar();
          _open(message);
        },
        titleText: Text(
          n.title ?? '',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        messageText: Text(
          n.body ?? '',
          style: TextStyle(fontSize: 12.5, color: AppColors.muted),
        ),
        icon: Icon(Icons.shopping_bag_outlined, color: AppColors.brand700),
      ),
    );
  }

  void _open(RemoteMessage message) {
    final data = message.data;
    if (data['type'] == 'CUSTOMER_ORDER' && (data['orderId'] ?? '').isNotEmpty) {
      Get.toNamed(Routes.customerOrderDetail, arguments: data['orderId']);
    }
  }
}
