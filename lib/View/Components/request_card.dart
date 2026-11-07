import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/request_models.dart';

/// One request row on the Requests screen.
class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.data, this.onTap});

  final RequestItemData data;
  final VoidCallback? onTap;

  Color get _statusColor {
    switch (data.status) {
      case RequestStatus.pending:
        return AppColors.warning;
      case RequestStatus.approved:
        return AppColors.success;
      case RequestStatus.rejected:
        return AppColors.danger;
    }
  }

  Color get _statusBg {
    switch (data.status) {
      case RequestStatus.pending:
        return AppColors.warningBg;
      case RequestStatus.approved:
        return AppColors.successBg;
      case RequestStatus.rejected:
        return AppColors.dangerBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.brand700.withAlpha(40)),
            borderRadius: BorderRadius.circular(18),
            // boxShadow: [
            //   BoxShadow(color: AppColors.brand900.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
            // ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(11)),
                    alignment: Alignment.center,
                    child: Text(
                      data.initials,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brand700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.requesterName,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${data.typeLabel} • ${data.requestId}',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: AppColors.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      data.status.label,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data.detail,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.submittedAgo,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
                    ),
                  ),
                  // The server says it is this person's turn to approve.
                  if (data.canAct && data.status == RequestStatus.pending)
                    Text(
                      'request_needs_your_action'.tr,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.brand700),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
