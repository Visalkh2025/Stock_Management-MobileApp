import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/stock_controller.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/View/Components/app_main_scaffold.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/stock_item_card.dart';

class StockScreen extends GetView<StockController> {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppMainScaffold(
      tab: AppNavTab.stock,
      body: Column(
        children: [
          _header(),
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
                    child: ListView.separated(
                    // Bottom padding clears the translucent nav bar (its
                    // height + its own bottom margin, plus a little
                    // breathing room) so the last card rests above it
                    // instead of underneath it.
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
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
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
            _searchToggleButton,
          ],
        ),
        _searchField,
        const SizedBox(height: 16),
        _categoryRow,
        const SizedBox(height: 10),
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

  Widget get _categoryRow {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppScreenHeader.onHeaderSurface,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.category_outlined, size: 15, color: AppScreenHeader.onHeader),
              const SizedBox(width: 8),
              Text(
                'stock_all_categories'.tr,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppScreenHeader.onHeader),
              ),
            ],
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppScreenHeader.onHeaderMuted),
        ],
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
            const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'empty_no_search_results'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
