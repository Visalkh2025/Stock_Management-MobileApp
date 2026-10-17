import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/approval_chain.dart';
import 'package:stock_management/View/Components/app_picker_field.dart';

/// "Approvers & Verification": who must sign off, in order. Same idea as the
/// web form — a reviewer + a role per row, plus "Add Approver". Backed by an
/// [ApprovalChain]; [helpText] explains what happens on the final approval.
class ApprovalChainCard extends StatelessWidget {
  const ApprovalChainCard({super.key, required this.chain, required this.helpText});

  final ApprovalChain chain;
  final String helpText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            helpText,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Obx(
            () => Column(
              children: [
                for (var i = 0; i < chain.drafts.length; i++) _row(i),
              ],
            ),
          ),
          InkWell(
            onTap: chain.addRow,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brand700.withAlpha(60)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, size: 16, color: AppColors.brand700),
                  const SizedBox(width: 6),
                  Text(
                    'action_add_approver'.tr,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.brand700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(int index) {
    final draft = chain.drafts[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brand700.withAlpha(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'label_step'.trParams({'n': '${index + 1}'}),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              if (chain.drafts.length > 1)
                InkWell(
                  onTap: () => chain.removeRow(index),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => AppPickerField(
              label: 'field_staff_reviewer'.tr,
              value: draft.reviewer.value,
              options: chain.reviewerOptionsFor(index),
              isLoading: chain.isLoadingCandidates.value,
              required: true,
              allowClear: false,
              fillColor: AppColors.cardBg,
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.textTertiary),
              onChanged: (v) => draft.reviewer.value = v,
            ),
          ),
          const SizedBox(height: 14),
          Obx(
            () => AppPickerField(
              label: 'field_signoff_role'.tr,
              value: draft.role.value,
              options: chain.roleOptions,
              required: true,
              allowClear: false,
              fillColor: AppColors.cardBg,
              prefixIcon: const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.textTertiary),
              onChanged: (v) => chain.setRole(draft, v),
            ),
          ),
        ],
      ),
    );
  }
}
