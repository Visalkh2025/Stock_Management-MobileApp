import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/lookup_models.dart';

/// Labeled field that opens a bottom-sheet list instead of a keyboard — for
/// picking a category / brand / supplier / warehouse from the server's list.
/// Looks like [AppTextField]; supports form validation via [required].
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hintText,
    this.required = false,
    this.isLoading = false,
    this.fillColor,
    this.prefixIcon,
    this.allowClear = true,
  });

  final String label;
  final LookupOption? value;
  final List<LookupOption> options;
  final ValueChanged<LookupOption?> onChanged;
  final String? hintText;
  final bool required;
  final bool isLoading;
  final Color? fillColor;
  final Widget? prefixIcon;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return FormField<LookupOption>(
      key: ValueKey('${label}_${value?.code}'),
      initialValue: value,
      validator: (v) => (required && v == null) ? 'validation_select_required'.tr : null,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isLoading ? null : () => _open(context, state),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: fillColor ?? AppColors.pageBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: state.hasError ? AppColors.danger : AppColors.border),
                ),
                child: Row(
                  children: [
                    if (prefixIcon != null) ...[prefixIcon!, const SizedBox(width: 10)],
                    Expanded(
                      child: Text(
                        isLoading ? '...' : (value?.name ?? hintText ?? 'hint_select'.tr),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.5, color: value == null ? AppColors.muted : AppColors.ink),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(state.errorText!, style: const TextStyle(fontSize: 11.5, color: AppColors.danger)),
              ),
          ],
        );
      },
    );
  }

  void _open(BuildContext context, FormFieldState<LookupOption> state) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ),
                if (options.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('no_options_available'.tr, style: const TextStyle(color: AppColors.muted)),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        if (allowClear && !required && value != null)
                          ListTile(
                            leading: const Icon(Icons.close_rounded, color: AppColors.muted),
                            title: Text('action_clear'.tr),
                            onTap: () {
                              onChanged(null);
                              state.didChange(null);
                              Navigator.of(sheetContext).pop();
                            },
                          ),
                        for (final option in options)
                          ListTile(
                            title: Text(option.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(option.code, style: const TextStyle(fontSize: 11.5)),
                            trailing: option == value ? const Icon(Icons.check_rounded, color: AppColors.brand600) : null,
                            onTap: () {
                              onChanged(option);
                              state.didChange(option);
                              Navigator.of(sheetContext).pop();
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
