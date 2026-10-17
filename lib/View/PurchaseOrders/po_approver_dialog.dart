import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Model/purchase_order_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/purchase_order_service.dart';

/// Lists the Admins / Super Admins that can approve a purchase order and pops
/// the id of the one picked (null when cancelled).
class PoApproverDialog extends StatefulWidget {
  const PoApproverDialog({super.key});

  @override
  State<PoApproverDialog> createState() => _PoApproverDialogState();
}

class _PoApproverDialogState extends State<PoApproverDialog> {
  late final Future<List<PoApprover>> _future = PurchaseOrderService().fetchApprovers();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('po_approver_dialog_title'.tr),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<PoApprover>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Text(error is ApiException ? error.message : error.toString());
            }
            final approvers = snapshot.data ?? const [];
            if (approvers.isEmpty) return Text('po_approver_empty'.tr);
            return ListView(
              shrinkWrap: true,
              children: [
                for (final a in approvers)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.how_to_reg_outlined),
                    title: Text(a.name),
                    subtitle: a.roles.isEmpty ? null : Text(a.roles.join(', ')),
                    onTap: () => Navigator.of(context).pop(a.id),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('action_cancel'.tr)),
      ],
    );
  }
}
