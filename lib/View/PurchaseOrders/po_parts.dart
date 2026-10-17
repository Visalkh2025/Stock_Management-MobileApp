import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';

/// Header of the purchase-order screens: back button + [title] (+ [trailing]).
class PoHeader extends StatelessWidget {
  const PoHeader({super.key, required this.title, this.trailing, this.below});

  final String title;
  final Widget? trailing;

  /// Extra content under the title row (e.g. the status chips).
  final Widget? below;

  @override
  Widget build(BuildContext context) {
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
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (below != null) ...[const SizedBox(height: 16), below!],
      ],
    );
  }
}

class PoSectionLabel extends StatelessWidget {
  const PoSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
    );
  }
}

/// White rounded card used by every section of these screens.
class PoCard extends StatelessWidget {
  const PoCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class PoStatusBadge extends StatelessWidget {
  const PoStatusBadge(this.status, {super.key});

  final PoStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: status.background, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.labelKey.tr,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: status.color),
      ),
    );
  }
}

/// `Label ........ value` row.
class PoInfoRow extends StatelessWidget {
  const PoInfoRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class PoErrorBanner extends StatelessWidget {
  const PoErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withAlpha(24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withAlpha(90)),
      ),
      child: Text(message, style: const TextStyle(fontSize: 12.5, color: AppColors.danger)),
    );
  }
}
