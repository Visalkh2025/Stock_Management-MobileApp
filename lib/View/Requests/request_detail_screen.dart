import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Controller/request_detail_controller.dart';
import 'package:stock_management/Model/request_models.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/View/Components/app_screen_header.dart';
import 'package:stock_management/View/Components/product_variant_row.dart';
import 'package:stock_management/View/Components/variant_price_summary.dart';

/// Approve/Reject a single request. Static demo — writes straight into
/// [RequestController]'s list (see [RequestDetailController]) and pops
/// back to the Requests list, no API yet.
class RequestDetailScreen extends GetView<RequestDetailController> {
  const RequestDetailScreen({super.key});

  RequestItemData get _request => controller.request;

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return AppColors.warning;
      case RequestStatus.approved:
        return AppColors.success;
      case RequestStatus.rejected:
        return AppColors.danger;
    }
  }

  Color _statusBg(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return AppColors.warningBg;
      case RequestStatus.approved:
        return AppColors.successBg;
      case RequestStatus.rejected:
        return AppColors.dangerBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => Column(
        children: [
          _header(context),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  _summaryCard,
                  const SizedBox(height: 16),
                  if (_request.productPayload != null) ..._productSections(_request.productPayload!) else _detailCard,
                  if (_request.remark != null) ...[
                    const SizedBox(height: 16),
                    _remarkCard,
                  ],
                  if (_request.approvers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _approversCard,
                  ],
                  const SizedBox(height: 24),
                  if (controller.errorMessage.value != null) _errorBanner(controller.errorMessage.value!),
                  if (controller.canAct)
                    _actionRow(context)
                  else if (controller.isPending)
                    _waitingBanner
                  else
                    _decidedBanner,
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _request.typeLabel,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppScreenHeader.onHeader),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _request.requestId,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppScreenHeader.onHeaderMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppScreenHeader.onHeaderSurface,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                _request.status.label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppScreenHeader.onHeader),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget get _summaryCard {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.brand700.withAlpha(30)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(
              _request.initials,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brand700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _request.requesterName,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  _request.submittedAgo,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: _statusBg(_request.status), borderRadius: BorderRadius.circular(9)),
            child: Text(
              _request.status.label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(_request.status)),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _detailCard {
    final segments = _request.detail.split('•').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.brand700.withAlpha(30)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'label_details'.tr,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
          ),
          const SizedBox(height: 10),
          for (final segment in segments)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(color: AppColors.brand600, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      segment,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _stockStatusColor(StockStatus status) {
    switch (status) {
      case StockStatus.inStock:
        return AppColors.success;
      case StockStatus.lowStock:
        return AppColors.warning;
      case StockStatus.outOfStock:
        return AppColors.danger;
    }
  }

  Color _stockStatusBg(StockStatus status) {
    switch (status) {
      case StockStatus.inStock:
        return AppColors.successBg;
      case StockStatus.lowStock:
        return AppColors.warningBg;
      case StockStatus.outOfStock:
        return AppColors.dangerBg;
    }
  }

  /// Product Create requests carry the full product [StockItemData] — this
  /// renders the same structured info/variants breakdown as Product Detail
  /// instead of the flat bullet-list fallback in [_detailCard].
  List<Widget> _productSections(StockItemData product) {
    return [
      _productInfoCard(product),
      const SizedBox(height: 16),
      product.hasVariants ? _productVariantsCard(product) : _productSimpleCard(product),
    ];
  }

  Widget _productInfoCard(StockItemData product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.brand700.withAlpha(30)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'label_product'.tr,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
          ),
          const SizedBox(height: 10),
          Text(product.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
          if ([product.brand, product.category].any((v) => v != null && v.isNotEmpty)) ...[
            const SizedBox(height: 2),
            Text(
              [product.brand, product.category].where((v) => v != null && v.isNotEmpty).join(' • '),
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.muted),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: AppColors.border),
          ),
          _productRow('field_sku'.tr, product.sku.isEmpty ? 'sku_assigned_on_approval'.tr : product.sku),
          _productRow('field_unit'.tr, product.unit),
          if (product.supplier != null && product.supplier!.isNotEmpty) _productRow('field_supplier'.tr, product.supplier!),
          if (product.barcode != null && product.barcode!.isNotEmpty) _productRow('field_barcode'.tr, product.barcode!),
          if (product.description != null && product.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              product.description!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _productRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ],
      ),
    );
  }

  Widget _productVariantsCard(StockItemData product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.brand700.withAlpha(30)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(
              'label_variants_count'.trParams({'count': '${product.variants.length}'}),
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
            ),
          ),
          for (final variant in product.variants)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductVariantRow(data: variant),
                  VariantMetaRow(variant: variant),
                  VariantSubtotalLine(variant: variant),
                  for (final stock in variant.warehouseStocks.where((s) => s.location != null))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${stock.warehouseName.isEmpty ? stock.warehouseCode : stock.warehouseName} • ${stock.location}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
                      ),
                    ),
                ],
              ),
            ),
          if (product.variants.any((v) => v.costPrice != null)) ...[
            const SizedBox(height: 4),
            TotalValueBox(
              label: 'total_cost_value_all_variants'.tr,
              value: product.variants.fold<double>(0, (sum, v) => sum + (v.costPrice ?? 0) * v.quantity),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _productSimpleCard(StockItemData product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.brand700.withAlpha(30)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('field_quantity'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Text('${product.quantity}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _stockStatusBg(product.status), borderRadius: BorderRadius.circular(9)),
                child: Text(
                  product.status.label,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _stockStatusColor(product.status)),
                ),
              ),
            ],
          ),
          if (product.warehouse.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'warehouse_prefix'.trParams({'wh': product.warehouse}),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
            ),
          ],
          for (final stock in product.warehouseStocks.where((s) => s.location != null))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${stock.warehouseName.isEmpty ? stock.warehouseCode : stock.warehouseName} • ${stock.location}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
                ),
              ),
            ),
          if (product.costPrice != null || product.sellingPrice != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, thickness: 1, color: AppColors.border),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('field_cost_price'.tr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text(formatPrice(product.costPrice), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('field_sale_price'.tr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text(formatPrice(product.sellingPrice), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
            if (product.costPrice != null) ...[
              const SizedBox(height: 14),
              TotalValueBox(label: 'total_cost_value'.tr, value: product.costPrice! * product.quantity),
            ],
          ],
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
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

  Widget get _remarkCard {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.brand700.withAlpha(30)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'label_remark'.tr,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          Text(_request.remark!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink, height: 1.4)),
        ],
      ),
    );
  }

  Color _approverColor(ApproverStatus status) {
    switch (status) {
      case ApproverStatus.waiting:
        return AppColors.textTertiary;
      case ApproverStatus.pending:
        return AppColors.warning;
      case ApproverStatus.approved:
        return AppColors.success;
      case ApproverStatus.rejected:
        return AppColors.danger;
    }
  }

  Color _approverBg(ApproverStatus status) {
    switch (status) {
      case ApproverStatus.waiting:
        return AppColors.pageBg;
      case ApproverStatus.pending:
        return AppColors.warningBg;
      case ApproverStatus.approved:
        return AppColors.successBg;
      case ApproverStatus.rejected:
        return AppColors.dangerBg;
    }
  }

  /// The approval chain, one row per step, in the order they must act.
  Widget get _approversCard {
    final approvers = _request.approvers;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.brand700.withAlpha(30)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'label_approval_workflow'.tr,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < approvers.length; i++) ...[
            if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, thickness: 1, color: AppColors.border)),
            _approverRow(approvers[i]),
          ],
        ],
      ),
    );
  }

  Widget _approverRow(ApproverData approver) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(11)),
              alignment: Alignment.center,
              child: Text(
                approver.initials,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brand700),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    approver.name.isEmpty ? approver.staffId : approver.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${'label_step'.trParams({'n': '${approver.step}'})} • ${approver.role.label}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: _approverBg(approver.status), borderRadius: BorderRadius.circular(8)),
              child: Text(
                approver.status.label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _approverColor(approver.status)),
              ),
            ),
          ],
        ),
        if (approver.remark != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              approver.remark!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted, height: 1.35),
            ),
          ),
        ],
      ],
    );
  }

  /// Pending, but not this person's turn (the requester, or someone later
  /// in the chain): say whose action it is waiting on instead of offering
  /// buttons they cannot use.
  Widget get _waitingBanner {
    final current = _request.currentApprover;
    final who = current == null ? '' : (current.name.isEmpty ? current.staffId : current.name);
    final message = !_request.isRemote
        ? 'request_local_only_note'.tr
        : (who.isEmpty ? 'request_waiting_generic'.tr : 'request_waiting_for'.trParams({'name': who}));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, size: 20, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _decidedBanner {
    final approved = _request.status == RequestStatus.approved;
    final reason = _request.rejectReason;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusBg(_request.status),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                approved ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                size: 20,
                color: _statusColor(_request.status),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  approved ? 'request_already_approved'.tr : 'request_already_rejected'.tr,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _statusColor(_request.status)),
                ),
              ),
            ],
          ),
          if (!approved && reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'reject_reason_prefix'.trParams({'reason': reason}),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(_request.status)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: 'action_reject'.tr,
            icon: Icons.close_rounded,
            background: AppColors.dangerBg,
            foreground: AppColors.danger,
            onTap: () => _confirmReject(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            label: 'action_approve'.tr,
            icon: Icons.check_rounded,
            background: AppColors.success,
            foreground: Colors.white,
            onTap: () => _confirm(
              context,
              title: 'confirm_approve_title'.tr,
              message: 'confirm_approve_message'.trParams({'id': _request.requestId}),
              confirmLabel: 'action_approve'.tr,
              confirmColor: AppColors.success,
              onConfirm: controller.approve,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: controller.isBusy.value ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: foreground),
              const SizedBox(width: 7),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: foreground)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReject(BuildContext context) {
    final reasonController = TextEditingController();
    String? errorText;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('confirm_reject_title'.tr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  'confirm_reject_message'.trParams({'id': _request.requestId}),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  autofocus: true,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'reject_reason_hint'.tr,
                    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                    errorText: errorText,
                    filled: true,
                    fillColor: AppColors.pageBg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.muted, width: 1.4),
                    ),
                  ),
                ),
              ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('action_cancel'.tr, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    setState(() => errorText = 'reject_reason_required'.tr);
                    return;
                  }
                  Navigator.of(dialogContext).pop();
                  controller.reject(reason);
                },
                child: Text('action_reject'.tr, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
        content: Text(message, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.muted)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('action_cancel'.tr, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onConfirm();
            },
            child: Text(confirmLabel, style: TextStyle(color: confirmColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
