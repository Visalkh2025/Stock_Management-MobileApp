import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/team_members_controller.dart';
import 'package:stock_management/Model/rbac_models.dart';
import 'package:stock_management/Model/team_member_models.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/swipe_actions.dart';

/// More > Team Members — flat searchable list, "+Add" in the header, and an edit/delete action on each row.
class TeamMembersScreen extends GetView<TeamMembersController> {
  const TeamMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header,
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                final items = controller.filteredItems;
                final isLoading = controller.isLoading.value;
                final error = controller.errorMessage.value;
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      if (isLoading && items.isEmpty)
                        _loadingState
                      else if (error != null && items.isEmpty)
                        _errorState(error)
                      else if (items.isEmpty)
                        _emptyState
                      else
                        for (final item in items) ...[
                          _memberCard(context, item),
                          const SizedBox(height: 8),
                        ],
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _header {
    return AppScreenHeader(
      children: [
        Row(
          children: [
            Material(
              color: AppScreenHeader.onHeaderSurface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: Get.back,
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: AppScreenHeader.onHeader,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'menu_team_members'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppScreenHeader.onHeader,
                ),
              ),
            ),
            if (can(Perm.userCreate)) Material(
              color: AppScreenHeader.onHeaderSurface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: controller.openAdd,
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: AppScreenHeader.onHeader,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _searchField,
      ],
    );
  }

  Widget get _searchField {
    return Container(
      height: 42,
      padding: EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: AppScreenHeader.onHeaderSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerLeft,
      // prefixIcon pins the icon to the field's far-left edge, so a merely centered hint ends up centered in the space *after* it — a visible gap between icon and text.
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppScreenHeader.onHeaderMuted,
            ),
            const SizedBox(width: 8),
            IntrinsicWidth(
              child: TextField(
                onChanged: controller.setSearch,
                style: const TextStyle(fontSize: 13.5, color: Colors.white),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: 'search_team_members'.tr,
                  hintStyle: TextStyle(
                    color: AppScreenHeader.onHeaderMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberCard(BuildContext context, TeamMemberData item) {
    return AppSwipeActions(
      borderRadius: BorderRadius.circular(16),
      onEdit: () => controller.openEdit(item),
      onDelete: () => controller.delete(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: accentBgFor(item.roleName),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.roleName,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: accentColorFor(item.roleName),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.brand50,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.initials,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.email,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget get _loadingState {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _errorState(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(
            'team_members_load_failed_title'.tr,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: controller.load,
            child: Text(
              'action_retry'.tr,
              style: const TextStyle(color: AppColors.brand600, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _emptyState {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 36,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 10),
          Text(
            'empty_team_members_title'.tr,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'empty_team_members_hint'.tr,
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
