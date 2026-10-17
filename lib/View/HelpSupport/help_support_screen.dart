import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/help_support_controller.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';

/// More > Help & Support — static FAQ list (expand/collapse) + a contact
/// card. See [HelpSupportController].
class HelpSupportScreen extends GetView<HelpSupportController> {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header,
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  _sectionLabel('section_faq'.tr),
                  const SizedBox(height: 10),
                  _faqCard,
                  const SizedBox(height: 18),
                  _sectionLabel('section_contact_us'.tr),
                  const SizedBox(height: 10),
                  _contactCard,
                ],
              ),
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
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppScreenHeader.onHeader),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'menu_help_support'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
    );
  }

  Widget get _faqCard {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Obx(
        () => Column(
          children: [
            for (var i = 0; i < controller.faqs.length; i++) ...[
              _faqRow(controller.faqs[i]),
              if (i != controller.faqs.length - 1)
                const Divider(height: 1, thickness: 1, color: AppColors.border, indent: 14, endIndent: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _faqRow(FaqItemData faq) {
    final isExpanded = controller.expandedQuestions.contains(faq.question);
    return InkWell(
      onTap: () => controller.toggleFaq(faq.question),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    faq.question.tr,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.expand_more_rounded, size: 20, color: AppColors.textTertiary),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topLeft,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        faq.answer.tr,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted, height: 1.4),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _contactCard {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _contactRow(
            icon: Icons.mail_outline_rounded,
            label: 'label_email_support'.tr,
            value: 'support@stockflow.com',
            onTap: () => controller.copyToClipboard('field_email'.tr, 'support@stockflow.com'),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border, indent: 14, endIndent: 14),
          _contactRow(
            icon: Icons.call_outlined,
            label: 'label_call_support'.tr,
            value: '+855 12 345 678',
            onTap: () => controller.copyToClipboard('label_phone_number'.tr, '+855 12 345 678'),
          ),
        ],
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(11)),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: AppColors.brand700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 1),
                  Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded, size: 15, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
