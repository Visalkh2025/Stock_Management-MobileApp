import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/customer_order_models.dart';
import 'package:stock_management/View/Components/app_button.dart';

/// Asks why a customer order is rejected (the customer is told the reason).
class CoReasonDialog extends StatefulWidget {
  const CoReasonDialog({super.key});

  @override
  State<CoReasonDialog> createState() => _CoReasonDialogState();
}

class _CoReasonDialogState extends State<CoReasonDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _text.text.trim();
    if (value.isNotEmpty) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('co_reject_title'.tr),
      content: TextField(
        controller: _text,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(hintText: 'co_reject_reason_hint'.tr),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('action_cancel'.tr)),
        TextButton(onPressed: _submit, child: Text('action_reject'.tr)),
      ],
    );
  }
}

class CoPaymentResult {
  const CoPaymentResult(this.amount, this.remark, {this.proof});

  final double amount;
  final String? remark;

  /// Photo of the transaction (optional).
  final File? proof;
}

/// Records the payment the customer agreed to: the amount (the order total to
/// start with), an optional note (e.g. how it was paid) and an optional photo
/// of the transaction.
class CoPaymentDialog extends StatefulWidget {
  const CoPaymentDialog({super.key, required this.total});

  final double total;

  @override
  State<CoPaymentDialog> createState() => _CoPaymentDialogState();
}

class _CoPaymentDialogState extends State<CoPaymentDialog> {
  late final TextEditingController _amount = TextEditingController(text: widget.total.toStringAsFixed(2));
  final _remark = TextEditingController();
  final _picker = ImagePicker();
  bool _invalid = false;
  File? _proof;

  @override
  void initState() {
    super.initState();
    // Select the prefilled amount so typing a different one replaces it.
    _amount.selection = TextSelection(baseOffset: 0, extentOffset: _amount.text.length);
    _amount.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _remark.dispose();
    super.dispose();
  }

  bool get _isFullAmount {
    final value = double.tryParse(_amount.text.trim());
    return value != null && (value - widget.total).abs() < 0.005;
  }

  void _useFullAmount() {
    final text = widget.total.toStringAsFixed(2);
    _amount.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    setState(() => _invalid = false);
  }

  void _submit() {
    final value = double.tryParse(_amount.text.trim());
    if (value == null || value <= 0) {
      setState(() => _invalid = true);
      return;
    }
    final note = _remark.text.trim();
    Navigator.of(context).pop(CoPaymentResult(value, note.isEmpty ? null : note, proof: _proof));
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (picked != null && mounted) setState(() => _proof = File(picked.path));
  }

  InputDecoration _decoration(String label, {String? prefix, String? error, String? hint}) {
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      errorText: error,
      filled: true,
      fillColor: AppColors.pageBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.brand700, 1.6),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.6),
    );
  }

  /// Order total in a soft card, so it is clear what the amount is compared to.
  Widget get _totalCard {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'co_payment_total'.tr,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
          ),
          Text(
            coMoney(widget.total),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.brand700),
          ),
        ],
      ),
    );
  }

  /// One tap target for the camera / the gallery: icon above the label, so the
  /// label never wraps.
  Widget _proofButton(IconData icon, String label, ImageSource source) {
    return Expanded(
      child: Material(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _pick(source),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(icon, size: 22, color: AppColors.brand700),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.brand700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "Transaction image": two buttons, or the chosen photo with a remove button.
  Widget get _proofPicker {
    final file = _proof;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'co_payment_proof'.tr,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        if (file == null)
          Row(
            children: [
              _proofButton(Icons.photo_camera_outlined, 'co_proof_camera'.tr, ImageSource.camera),
              const SizedBox(width: 10),
              _proofButton(Icons.photo_library_outlined, 'co_proof_gallery'.tr, ImageSource.gallery),
            ],
          )
        else
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(file, height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => setState(() => _proof = null),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBg,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.brand50, shape: BoxShape.circle),
                    child: Icon(Icons.payments_outlined, size: 20, color: AppColors.brand700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'co_payment_title'.tr,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _totalCard,
              const SizedBox(height: 16),
              TextField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                onChanged: (_) {
                  if (_invalid) setState(() => _invalid = false);
                },
                decoration: _decoration(
                  'co_payment_amount'.tr,
                  prefix: '\$ ',
                  error: _invalid ? 'co_payment_invalid'.tr : null,
                ),
              ),
              if (!_isFullAmount)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _useFullAmount,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text('co_payment_full'.tr),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brand700,
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              else
                const SizedBox(height: 12),
              TextField(
                controller: _remark,
                maxLines: 2,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration('co_payment_note'.tr),
              ),
              const SizedBox(height: 16),
              _proofPicker,
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'action_cancel'.tr,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(label: 'co_action_paid'.tr, icon: Icons.check_rounded, onPressed: _submit),
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
