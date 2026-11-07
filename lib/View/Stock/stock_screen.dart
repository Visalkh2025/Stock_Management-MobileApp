import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/stock_controller.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/View/Components/app_main_scaffold.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/stock_item_card.dart';
import 'package:stock_management/View/Components/stock_item_grid_card.dart';

class StockScreen extends GetView<StockController> {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppMainScaffold(
      tab: AppNavTab.stock,
      body: Column(
        children: [
          _header(),
          _facetRows,
          Expanded(
            // extendBody (AppMainScaffold) lets this reach all the way to the
            // bottom of the screen instead of stopping above the nav bar —
            // don't let SafeArea's default bottom inset undo that.
            child: SafeArea(
              top: false,
              bottom: false,
              child: Obx(
                () {
                  final items = controller.filteredItems;
                  if (controller.isLoading.value && items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final error = controller.errorMessage.value;
                  if (error != null && items.isEmpty) {
                    return _errorState(error);
                  }
                  if (items.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: controller.load,
                      child: ListView(children: [SizedBox(height: 320, child: _emptyState)]),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: controller.load,
                    child: controller.isGridView.value ? _grid(context, items) : _list(context, items),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, List<StockItemData> items) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.paddingOf(context).bottom * 0.5 + 76),
      itemCount: items.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return Obx(
          () => StockItemCard(
            data: item,
            onTap: () => controller.openItem(item),
            expanded: controller.expandedSkus.contains(item.sku),
            onToggleExpand: () => controller.toggleExpanded(item.sku),
          ),
        );
      },
    );
  }

  Widget _grid(BuildContext context, List<StockItemData> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns with 20px page padding and a 12px gap.
        final cardWidth = (constraints.maxWidth - 40 - 12) / 2;
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.paddingOf(context).bottom * 0.5 + 76),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            // photo (card width - padding) + name, SKU and quantity rows.
            mainAxisExtent: cardWidth + 92,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return StockItemGridCard(
              data: item,
              imageSize: cardWidth - 20,
              onTap: () => controller.openItem(item),
            );
          },
        );
      },
    );
  }

  /// Category chips, and — once a category is picked — its brand chips.
  Widget get _facetRows {
    return Obx(() {
      final categories = controller.categoryFacets;
      if (categories.isEmpty) return const SizedBox.shrink();
      final brands = controller.brandFacets;
      final selectedCategory = controller.selectedCategory.value;
      final selectedBrand = controller.selectedBrand.value;
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chipScroller([
              _facetChip(
                label: 'filter_all'.tr,
                count: controller.categoryAllCount,
                active: selectedCategory == null,
                onTap: () => controller.setCategory(null),
              ),
              for (final c in categories)
                _facetChip(
                  label: c.label,
                  count: c.count,
                  active: selectedCategory == c.key,
                  onTap: () => controller.setCategory(c.key),
                ),
            ]),
            if (brands.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _chipScroller([
                  Text(
                    'stock_brand_label'.tr,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.muted,
                    ),
                  ),
                  _facetChip(
                    label: 'stock_all_brands'.tr,
                    active: selectedBrand == null,
                    small: true,
                    onTap: () => controller.setBrand(null),
                  ),
                  for (final b in brands)
                    _facetChip(
                      label: b.label,
                      active: selectedBrand == b.key,
                      small: true,
                      onTap: () => controller.setBrand(b.key),
                    ),
                ]),
              ),
          ],
        ),
      );
    });
  }

  Widget _chipScroller(List<Widget> children) {
    // Full-width row that always starts at the left edge (even when the chips
    // are few), and whose right edge fades so it's clear the row scrolls.
    return SizedBox(
      width: double.infinity,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0, 0.94, 1],
        ).createShader(rect),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth - 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Category chip (big, filled when active) or — with [small] — a brand
  /// chip: white pill with a first-letter avatar (or [icon]), a count, and a
  /// check mark + purple tint when active.
  Widget _facetChip({
    required String label,
    int? count,
    required bool active,
    required VoidCallback onTap,
    bool small = false,
    String? initial,
    IconData? icon,
  }) {
    final Color fill = small ? (active ? AppColors.brand50 : AppColors.cardBg) : (active ? AppColors.brand700 : AppColors.cardBg);
    final Color text = small
        ? (active ? AppColors.brand700 : AppColors.ink)
        : (active ? Colors.white : AppColors.ink);
    final Color countFg = small
        ? (active ? AppColors.brand700 : AppColors.muted)
        : (active ? Colors.white : AppColors.muted);

    Widget? leading;
    if (small && icon != null) {
      leading = Icon(icon, size: 15, color: AppColors.muted);
    } else if (small && initial != null && initial.isNotEmpty) {
      leading = Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.brand50, shape: BoxShape.circle),
        child: Text(
          String.fromCharCode(initial.runes.first).toUpperCase(),
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.brand700),
        ),
      );
    }

    return Material(
      color: fill,
      shape: StadiumBorder(
        side: BorderSide(color: active ? AppColors.brand700 : AppColors.border, width: active && small ? 1.4 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          height: small ? 34 : 36,
          padding: EdgeInsets.only(left: leading != null ? 8 : (small ? 14 : 14), right: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontSize: small ? 12.5 : 13, fontWeight: FontWeight.w600, color: text)),
              if (count != null) ...[
                const SizedBox(width: 8),
                if (small)
                  Text('$count', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: countFg))
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: active ? Colors.white.withAlpha(56) : AppColors.pageBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: countFg),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            TextButton(onPressed: controller.load, child: Text('action_retry'.tr)),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return AppScreenHeader(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'nav_stock'.tr,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
              ),
            ),
            _addButton,
            const SizedBox(width: 8),
            _viewToggleButton,
            const SizedBox(width: 8),
            _searchToggleButton,
          ],
        ),
        _searchField,
        const SizedBox(height: 14),
        _filterChips,
      ],
    );
  }

  Widget get _addButton {
    return Material(
      color: AppScreenHeader.onHeaderSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: controller.addStockItem,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(Icons.add_rounded, size: 20, color: AppScreenHeader.onHeader),
        ),
      ),
    );
  }

  Widget get _viewToggleButton {
    return Obx(() {
      final grid = controller.isGridView.value;
      return Tooltip(
        message: grid ? 'stock_view_list'.tr : 'stock_view_grid'.tr,
        child: Material(
          color: AppScreenHeader.onHeaderSurface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => controller.setGridView(!grid),
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                size: 19,
                color: AppScreenHeader.onHeader,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget get _searchToggleButton {
    return Obx(
      () {
        final active = controller.isSearchActive.value;
        return Material(
          color: active ? Colors.white : AppScreenHeader.onHeaderSurface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: controller.toggleSearch,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                active ? Icons.close_rounded : Icons.search_rounded,
                size: 18,
                color: active ? AppColors.brand700 : AppScreenHeader.onHeader,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget get _searchField {
    return Obx(
      () => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: controller.isSearchActive.value
            ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppScreenHeader.onHeaderSurface,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 18, color: AppScreenHeader.onHeaderMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller.searchController,
                          focusNode: controller.searchFocusNode,
                          onChanged: controller.setSearchQuery,
                          cursorColor: Colors.white,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppScreenHeader.onHeader),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: 'stock_search_hint'.tr,
                            hintStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppScreenHeader.onHeaderMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox(width: double.infinity, height: 0),
      ),
    );
  }

  Widget get _filterChips {
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Counts can push these wider than the header — scroll instead of
        // overflowing off the right edge. Top padding leaves room for the
        // trailing count badges, which float above the pill's top edge.
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _chip('filter_all'.tr, controller.allCount, StockFilter.all),
              const SizedBox(width: 10),
              _chip('filter_low_stock'.tr, controller.lowCount, StockFilter.low),
              const SizedBox(width: 10),
              _chip('filter_out'.tr, controller.outCount, StockFilter.out),
            ],
          ),
        ),
      ),
    );
  }

  // Count shows as a small circular badge in the pill's top-right corner
  // instead of inline text, so the label stays clean at a glance.
  Widget _chip(String label, int count, StockFilter filter) {
    final isActive = controller.activeFilter.value == filter;
    Color bg;
    Color fg;
    if (isActive) {
      bg = Colors.white;
      fg = AppColors.brand700;
    } else if (filter == StockFilter.low) {
      bg = AppColors.warningBg;
      fg = AppColors.warning;
    } else if (filter == StockFilter.out) {
      bg = AppColors.dangerBg;
      fg = AppColors.danger;
    } else {
      bg = AppScreenHeader.onHeaderSurface;
      fg = AppScreenHeader.onHeader;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => controller.setFilter(filter),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                border: isActive || filter != StockFilter.all
                    ? null
                    : Border.all(color: AppScreenHeader.onHeaderSurfaceBorder),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
              ),
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18),
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: fg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '$count',
              // All's inactive badge sits on a near-white bg (fg ==
              // AppScreenHeader.onHeader there) — purple reads there;
              // every other badge is a solid color, where white still does.
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: !isActive && filter == StockFilter.all ? AppColors.brand700 : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget get _emptyState {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'empty_no_search_results'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
