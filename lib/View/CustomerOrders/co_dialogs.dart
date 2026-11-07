import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stock_management/Model/customer_order_models.dart';

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
/// start with) and an optional note, e.g. how it was paid.
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
  void dispose() {
    _amount.dispose();
    _remark.dispose();
    super.dispose();
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

  /// "Transaction image": two buttons, or the chosen photo with a remove button.
  Widget get _proofPicker {
    final file = _proof;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('co_payment_proof'.tr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (file == null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: Text('co_proof_camera'.tr),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text('co_proof_gallery'.tr),
                ),
              ),
            ],
          )
        else
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file, height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 6,
                right: 6,
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
    return AlertDialog(
      title: Text('co_payment_title'.tr),
      content: SingleChildScrollView(
       child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('co_payment_message'.trParams({'total': coMoney(widget.total)}), style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              labelText: 'co_payment_amount'.tr,
              prefixText: '\$ ',
              errorText: _invalid ? 'co_payment_invalid'.tr : null,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _remark,
            decoration: InputDecoration(labelText: 'co_payment_note'.tr),
          ),
          const SizedBox(height: 14),
          _proofPicker,
        ],
       ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('action_cancel'.tr)),
        TextButton(onPressed: _submit, child: Text('co_action_paid'.tr)),
      ],
    );
  }
}
