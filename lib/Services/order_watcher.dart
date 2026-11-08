import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/customer_orders_controller.dart';
import 'package:stock_management/Controller/notifications_controller.dart';
import 'package:stock_management/Controller/profile_controller.dart';
import 'package:stock_management/Model/customer_order_models.dart';
import 'package:stock_management/Services/customer_order_service.dart';

/// Keeps an eye on customer orders (Mini App) while the app is open, with no
/// help from the server: it asks for the orders waiting for review every
/// [interval] and when the app comes back to the front, and shows a tappable
/// banner when a new one has arrived.
///
/// This works against any server that has `GET /customer-orders`. It does NOT
/// reach a phone whose app is closed — that needs push (Firebase), which the
/// server has to send.
class OrderWatcher with WidgetsBindingObserver {
  OrderWatcher._();
  static final OrderWatcher instance = OrderWatcher._();

  static const Duration interval = Duration(seconds: 45);

  final _service = CustomerOrderService();

  /// Orders waiting for review that this person has not looked at yet
  /// (drives the red number on the bell on Home). Opening the notifications
  /// screen, the orders list or one order clears it for what was shown.
  final pendingCount = 0.obs;

  Set<String> _seenOrders = {};
  Set<String> _pendingIds = {};
  String _uid = '';

  Timer? _timer;
  Set<String>? _seen; // null until the first answer, so old orders don't pop up
  bool _checking = false;

  void start() {
    if (_timer != null) return;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(interval, (_) => check());
    check();
  }

  /// Sign-out: stop asking and forget what was seen.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _seen = null;
    _pendingIds = {};
    _seenOrders = {};
    _uid = '';
    pendingCount.value = 0;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) check();
  }

  String get _me => Get.isRegistered<ProfileController>() ? Get.find<ProfileController>().userId : '';

  Future<void> _loadSeen(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    _seenOrders = (prefs.getStringList('badge_seen_orders_$uid') ?? const []).toSet();
  }

  /// These orders were looked at: the number drops straight away.
  Future<void> markSeen(Iterable<String> ids) async {
    final fresh = ids.where((id) => !_seenOrders.contains(id)).toList();
    if (fresh.isEmpty) return;
    _seenOrders = {..._seenOrders, ...fresh};
    pendingCount.value = _pendingIds.difference(_seenOrders).length;
    if (_uid.isEmpty) return;
    final kept = _seenOrders.toList();
    final prefs = await SharedPreferences.getInstance();
    // Only the newest 500 are kept, so this never grows forever.
    await prefs.setStringList('badge_seen_orders_$_uid', kept.length > 500 ? kept.sublist(kept.length - 500) : kept);
  }

  Future<void> check() async {
    if (_checking) return;
    _checking = true;
    try {
      final pending = await _service.fetchPending();
      final uid = _me;
      if (uid.isNotEmpty && uid != _uid) {
        _uid = uid;
        await _loadSeen(uid);
      }

      final ids = pending.map((o) => o.id).toSet();
      _pendingIds = ids;
      pendingCount.value = ids.difference(_seenOrders).length;
      final seen = _seen;
      _seen = ids;
      if (seen == null) return; // first answer: just learn what is there

      final fresh = pending.where((o) => !seen.contains(o.id)).toList();
      if (fresh.isEmpty) return;

      if (Get.isRegistered<CustomerOrdersController>()) Get.find<CustomerOrdersController>().load();
      if (Get.isRegistered<NotificationsController>()) Get.find<NotificationsController>().load();
      _banner(fresh);
    } catch (_) {
      // Offline or no access: stay quiet, try again next time.
    } finally {
      _checking = false;
    }
  }

  void _banner(List<CustomerOrderSummary> fresh) {
    final first = fresh.first;
    final more = fresh.length - 1;
    final title = 'notifications_new_order'.trParams({'no': first.orderNo});
    final body = more > 0
        ? '${first.customer.title} • +$more'
        : '${first.customer.title} • ${coMoney(first.totalAmount)}';
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.showSnackbar(
      GetSnackBar(
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.cardBg,
        borderRadius: 16,
        borderColor: AppColors.brand700.withAlpha(90),
        borderWidth: 1,
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        duration: const Duration(seconds: 6),
        isDismissible: true,
        onTap: (_) {
          Get.closeCurrentSnackbar();
          Get.toNamed(fresh.length == 1 ? Routes.customerOrderDetail : Routes.notifications,
              arguments: fresh.length == 1 ? first.id : null);
        },
        titleText: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
        messageText: Text(body, style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
        icon: Icon(Icons.shopping_bag_outlined, color: AppColors.brand700),
      ),
    );
  }
}
