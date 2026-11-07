import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/stock_history_models.dart';

/// Home "Recent activity": the latest stock movements as a compact timeline
/// list (type icon, product, type • where • when, signed quantity).
class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.entries,
    required this.isLoading,
    required this.error,
    required this.timeAgo,
    required this.onSeeAll,
  });

  final List<StockHistoryEntry> entries;
  final bool isLoading;
  final String? error;
  final String Function(DateTime?) timeAgo;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.brand900.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'home_activity_title'.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              InkWell(
                onTap: onSeeAll,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'home_activity_see_all'.tr,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brand700),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.brand700),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(
                        error ?? 'home_activity_empty'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                      ),
              ),
            )
          else
            for (var i = 0; i < entries.length; i++) ...[
              _ActivityRow(entry: entries[i], when: timeAgo(entries[i].at)),
              if (i != entries.length - 1) Divider(height: 1, color: AppColors.border),
            ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry, required this.when});

  final StockHistoryEntry entry;
  final String when;

  (IconData, Color, Color, String) get _look {
    switch (entry.kind) {
      case 'IN':
        return (Icons.south_west_rounded, AppColors.success, AppColors.successBg, 'history_kind_in'.tr);
      case 'OUT':
        return (Icons.north_east_rounded, AppColors.danger, AppColors.dangerBg, 'history_kind_out'.tr);
      case 'TRANSFER':
        return (Icons.swap_horiz_rounded, AppColors.brand700, AppColors.brand50, 'history_kind_transfer'.tr);
      default:
        return (Icons.tune_rounded, AppColors.warning, AppColors.warningBg, 'history_kind_adjustment'.tr);
    }
  }

  String get _qty {
    final q = entry.quantity;
    final n = q == q.roundToDouble() ? q.round().toString() : q.toStringAsFixed(2);
    switch (entry.kind) {
      case 'IN':
        return '+$n';
      case 'OUT':
        return '−$n';
      case 'ADJUSTMENT':
        return entry.toWarehouse != null ? '+$n' : '−$n';
      default:
        return n;
    }
  }

  String get _where {
    final from = entry.fromWarehouse;
    final to = entry.toWarehouse;
    if (from != null && to != null) return '$from → $to';
    return to ?? from ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg, label) = _look;
    final name = entry.variantName == null ? entry.productName : '${entry.productName} • ${entry.variantName}';
    final sub = [label, if (_where.isNotEmpty) _where, if (when.isNotEmpty) when].join(' • ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 1),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_qty, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
