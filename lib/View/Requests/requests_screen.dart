import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/request_controller.dart';
import 'package:stock_management/Model/request_models.dart';
import 'package:stock_management/View/Components/app_main_scaffold.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/request_card.dart';

class RequestsScreen extends GetView<RequestController> {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppMainScaffold(
      tab: AppNavTab.requests,
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
                  final error = controller.errorMessage.value;
                  if (controller.isLoading.value && items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
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
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.paddingOf(context).bottom * 0.5 + 76),
                      itemCount: items.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => RequestCard(
                        data: items[index],
                        onTap: () => controller.openRequest(items[index]),
                      ),
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
                'nav_requests'.tr,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
              ),
            ),
            _addButton,
          ],
        ),
        const SizedBox(height: 16),
        _statusChips,
      ],
    );
  }

  Widget get _addButton {
    return Material(
      color: AppScreenHeader.onHeaderSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: controller.createRequest,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(Icons.add_rounded, size: 20, color: AppScreenHeader.onHeader),
        ),
      ),
    );
  }

  Widget get _statusChips {
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
              _chip('filter_all'.tr, controller.totalCount, null),
              const SizedBox(width: 10),
              _chip('status_pending'.tr, controller.countFor(RequestStatus.pending), RequestStatus.pending),
              const SizedBox(width: 10),
              _chip('status_approved'.tr, controller.countFor(RequestStatus.approved), RequestStatus.approved),
              const SizedBox(width: 10),
              _chip('status_rejected'.tr, controller.countFor(RequestStatus.rejected), RequestStatus.rejected),
              const SizedBox(width: 10)
            ],
          ),
        ),
      ),
    );
  }

  // Count shows as a small circular badge in the pill's top-right corner
  // instead of inline text, so the label stays clean at a glance. Same
  // pattern as Stock's _filterChips: each status keeps its own
  // warning/success/danger tint instead of sharing All's neutral look.
  Widget _chip(String label, int count, RequestStatus? status) {
    final isActive = controller.activeFilter.value == status;
    Color bg;
    Color fg;
    if (isActive) {
      bg = Colors.white;
      fg = AppColors.brand700;
    } else {
      switch (status) {
        case null:
          bg = AppScreenHeader.onHeaderSurface;
          fg = AppScreenHeader.onHeader;
        case RequestStatus.pending:
          bg = AppColors.warningBg;
          fg = AppColors.warning;
        case RequestStatus.approved:
          bg = AppColors.successBg;
          fg = AppColors.success;
        case RequestStatus.rejected:
          bg = AppColors.dangerBg;
          fg = AppColors.danger;
      }
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => controller.setFilter(status),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                border: isActive || status != null ? null : Border.all(color: AppScreenHeader.onHeaderSurfaceBorder),
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
                color: !isActive && status == null ? AppColors.brand700 : Colors.white,
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
            const Icon(Icons.assignment_outlined, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'requests_empty_state'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
