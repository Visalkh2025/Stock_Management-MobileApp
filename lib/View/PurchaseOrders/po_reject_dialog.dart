import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Asks why a purchase order is rejected.
class PoRejectDialog extends StatefulWidget {
  const PoRejectDialog({super.key});

  @override
  State<PoRejectDialog> createState() => _PoRejectDialogState();
}

class _PoRejectDialogState extends State<PoRejectDialog> {
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
      title: Text('po_reject_title'.tr),
      content: TextField(
        controller: _text,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(hintText: 'po_reject_reason_hint'.tr),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('action_cancel'.tr)),
        TextButton(onPressed: _submit, child: Text('action_reject'.tr)),
      ],
    );
  }
}
