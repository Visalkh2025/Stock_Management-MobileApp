import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';

enum DatePreset { all, today, last7, last30, custom }

/// A date filter for lists: everything, today, the last 7 / 30 days, or a
/// range the person picks. [from] is the first moment included and [to] the
/// first moment *not* included (both in local time); null = no limit.
class DateFilter {
  const DateFilter([this.preset = DatePreset.all, this.custom]);

  final DatePreset preset;
  final DateTimeRange? custom;

  bool get isActive => preset != DatePreset.all;

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? get from {
    final today = _startOfDay(DateTime.now());
    switch (preset) {
      case DatePreset.all:
        return null;
      case DatePreset.today:
        return today;
      case DatePreset.last7:
        return DateTime(today.year, today.month, today.day - 6);
      case DatePreset.last30:
        return DateTime(today.year, today.month, today.day - 29);
      case DatePreset.custom:
        return custom == null ? null : _startOfDay(custom!.start);
    }
  }

  DateTime? get to {
    if (preset != DatePreset.custom || custom == null) return null;
    final end = custom!.end;
    return DateTime(end.year, end.month, end.day + 1);
  }

  /// Whether [time] falls inside the range (always true for "all dates").
  bool contains(DateTime time) {
    final start = from;
    final end = to;
    if (start != null && time.isBefore(start)) return false;
    if (end != null && !time.isBefore(end)) return false;
    return true;
  }

  /// Short name of the range for a caption, e.g. "Last 7 days" or "12/10 - 20/10".
  String get rangeLabel {
    switch (preset) {
      case DatePreset.all:
        return 'date_all'.tr;
      case DatePreset.today:
        return 'date_today'.tr;
      case DatePreset.last7:
        return 'last_7_days'.tr;
      case DatePreset.last30:
        return 'last_30_days'.tr;
      case DatePreset.custom:
        return customLabel;
    }
  }

  /// What the API takes: ISO timestamps in UTC (so the day boundaries are the
  /// phone's local midnights).
  String? get fromParam => from?.toUtc().toIso8601String();
  String? get toParam => to?.toUtc().toIso8601String();

  String _short(DateTime d) {
    final text = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return d.year == DateTime.now().year ? text : '$text/${d.year}';
  }

  String get customLabel {
    final range = custom;
    if (range == null) return 'date_custom'.tr;
    if (_startOfDay(range.start) == _startOfDay(range.end)) return _short(range.start);
    return '${_short(range.start)} - ${_short(range.end)}';
  }
}

/// The date chips under a purple screen header: All dates / Today / 7 days /
/// 30 days / Pick dates.
class DateFilterBar extends StatelessWidget {
  const DateFilterBar({super.key, required this.value, required this.onChanged, this.showAll = true});

  final DateFilter value;
  final ValueChanged<DateFilter> onChanged;

  /// false hides the "All dates" chip (for screens that need a bounded range).
  final bool showAll;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showAll) ...[
            _chip(context, 'date_all'.tr, DatePreset.all, icon: Icons.calendar_today_rounded),
            const SizedBox(width: 8),
          ],
          _chip(context, 'date_today'.tr, DatePreset.today, icon: showAll ? null : Icons.calendar_today_rounded),
          const SizedBox(width: 8),
          _chip(context, 'date_7_days'.tr, DatePreset.last7),
          const SizedBox(width: 8),
          _chip(context, 'date_30_days'.tr, DatePreset.last30),
          const SizedBox(width: 8),
          _chip(
            context,
            value.preset == DatePreset.custom ? value.customLabel : 'date_custom'.tr,
            DatePreset.custom,
            icon: Icons.date_range_rounded,
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, DatePreset preset, {IconData? icon}) {
    final active = value.preset == preset;
    final fg = active ? AppColors.brand700 : AppScreenHeader.onHeader;
    return Material(
      color: active ? Colors.white : AppScreenHeader.onHeaderSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => preset == DatePreset.custom ? _pickRange(context) : onChanged(DateFilter(preset)),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 5)],
              Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: value.custom,
    );
    if (picked != null) onChanged(DateFilter(DatePreset.custom, picked));
  }
}
