import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_management/Controller/profile_controller.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/product_service.dart';
import 'package:stock_management/Services/request_service.dart';
import 'package:stock_management/View/Components/app_main_scaffold.dart';

/// The red numbers on the bottom bar, both read from the API:
///  - Requests: requests waiting for this person's decision (or answered
///    requests of their own) they have not looked at yet.
///  - Stock: products added since they last opened the Stock tab.
/// Opening the tab clears its number; anything new shows it again.
class NavBadgeController extends GetxController {
  final _requests = RequestService();
  final _products = ProductService();

  final requestsBadge = 0.obs;
  final stockBadge = 0.obs;

  static const _pollEvery = Duration(seconds: 45);

  Timer? _timer;
  AppNavTab? _activeTab;
  String _uid = '';

  Set<String> _seenRequests = {};
  Set<String> _seenProducts = {};
  bool _productsSeeded = false;
  Set<String> _currentRequests = {};
  Set<String> _currentProducts = {};

  @override
  void onInit() {
    super.onInit();
    refresh();
    _timer = Timer.periodic(_pollEvery, (_) => refresh());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  String get _me => Get.isRegistered<ProfileController>() ? Get.find<ProfileController>().userId : '';

  /// Called by the bottom bar's screen: the tab being shown right now never
  /// keeps a badge on itself.
  Future<void> setActiveTab(AppNavTab tab) async {
    _activeTab = tab;
    await refresh();
  }

  Future<void> _loadPrefs(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    _seenRequests = (prefs.getStringList('badge_seen_requests_$uid') ?? const []).toSet();
    _seenProducts = (prefs.getStringList('badge_seen_products_$uid') ?? const []).toSet();
    _productsSeeded = prefs.getBool('badge_products_seeded_$uid') ?? false;
  }

  Future<void> _savePrefs() async {
    if (_uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('badge_seen_requests_$_uid', _seenRequests.toList());
    await prefs.setStringList('badge_seen_products_$_uid', _seenProducts.toList());
    await prefs.setBool('badge_products_seeded_$_uid', _productsSeeded);
  }

  Future<void> refresh() async {
    final uid = _me;
    if (uid.isEmpty) {
      requestsBadge.value = 0;
      stockBadge.value = 0;
      return;
    }
    if (uid != _uid) {
      _uid = uid;
      await _loadPrefs(uid);
    }
    await Future.wait([_refreshRequests(), _refreshStock()]);
    if (_activeTab == AppNavTab.requests && requestsBadge.value > 0) await markRequestsSeen();
    if (_activeTab == AppNavTab.stock && stockBadge.value > 0) await markStockSeen();
  }

  Future<void> _refreshRequests() async {
    try {
      final rows = await _requests.fetchAll();
      final keys = <String>{};
      for (final r in rows) {
        final id = r['id']?.toString();
        if (id == null) continue;
        final status = (r['status'] ?? '').toString();
        final approvers = (r['approvers'] as List? ?? const []);
        final waitingOnMe = status == 'PENDING' && approvers.any((a) => a is Map && a['canAct'] == true);
        final mineAnswered = status != 'PENDING' && r['requesterId']?.toString() == _uid;
        if (waitingOnMe || mineAnswered) keys.add('$id:$status');
      }
      _currentRequests = keys;
      requestsBadge.value = keys.difference(_seenRequests).length;
    } on ApiException {
      // Keep the last number; try again next time.
    }
  }

  Future<void> _refreshStock() async {
    try {
      final items = await _products.fetchProducts();
      final ids = <String>{
        for (final p in items)
          if ((p.id ?? p.code ?? '').isNotEmpty) (p.id ?? p.code)!,
      };
      _currentProducts = ids;
      if (!_productsSeeded) {
        // First time on this phone: everything already there is not "new".
        _seenProducts = {...ids};
        _productsSeeded = true;
        await _savePrefs();
      }
      stockBadge.value = ids.difference(_seenProducts).length;
    } on ApiException {
      // Keep the last number; try again next time.
    }
  }

  /// The Requests tab was opened: clear its number.
  Future<void> markRequestsSeen() async {
    _seenRequests = {..._seenRequests, ..._currentRequests};
    requestsBadge.value = 0;
    await _savePrefs();
  }

  /// The Stock tab was opened: clear its number.
  Future<void> markStockSeen() async {
    _seenProducts = {..._seenProducts, ..._currentProducts};
    stockBadge.value = 0;
    await _savePrefs();
  }
}
