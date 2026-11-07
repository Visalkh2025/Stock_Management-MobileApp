import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Controller/stock_form_controller.dart';
import 'package:stock_management/Controller/stock_line.dart';
import 'package:stock_management/Model/lookup_models.dart';

/// Which way an adjustment moves the count — unlike Stock In/Out (always +
/// or always -), one Adjustment screen has to support both, so each line has
/// a toggle the user picks rather than baking it into a route.
enum AdjustmentDirection { increase, decrease }

extension AdjustmentDirectionX on AdjustmentDirection {
  bool get isIncrease => this == AdjustmentDirection.increase;
  String get label => isIncrease ? 'direction_increase'.tr : 'direction_decrease'.tr;
  IconData get icon => isIncrease ? Icons.add_rounded : Icons.remove_rounded;
}

/// Reached from Home's "Adjust" quick action (see HomeController.
/// openAdjust / Routes.adjust). Corrects a product's on-hand quantity up or
/// down (damage, loss, recount, found stock, ...) with a Current -> After
/// preview. Someone with STOCK_ADJUST (ADMIN) saves straight to
/// `POST /stock-adjustments`; anyone else would send a STOCK_ADJUSTMENT
/// request — see [StockFormController].
class AdjustController extends StockFormController {
  @override
  String get requestType => 'STOCK_ADJUSTMENT';

  @override
  bool get needsApproval => !can(Perm.stockAdjust);

  @override
  bool get perLineDirection => true;

  @override
  bool get productFirst => true;

  @override
  LookupOption? incomingWarehouseOf(StockLine line) => line.increase.value ? line.warehouse.value : null;

  /// Only warehouses that already hold the product can be adjusted.
  @override
  List<LookupOption> warehouseOptionsFor(StockLine line) {
    if (line.product.value == null) return warehouses;
    return [for (final (w, _) in storedWarehouses(line, inStockOnly: !line.increase.value)) w];
  }

  @override
  LineImpact? impactOf(StockLine line) {
    final product = line.product.value;
    final current = line.onHandIn(line.warehouse.value);
    if (product == null || current == null) return null;
    final increase = line.increase.value;
    final qty = line.enteredQty.value;
    final after = qty == null ? null : (increase ? current + qty : current - qty);
    final exceeds = !increase && qty != null && qty > current;
    final minStock = product.minStock;
    final breach = !increase && !exceeds && after != null && minStock != null && after <= minStock;
    return LineImpact(
      leftLabel: 'stat_current'.tr,
      leftValue: '$current',
      rightLabel: 'stat_after'.tr,
      rightValue: after == null ? '—' : '$after',
      tone: increase ? ImpactTone.positive : ((breach || exceeds) ? ImpactTone.danger : ImpactTone.neutral),
      warning: exceeds
          ? 'exceeds_on_hand_warning'.trParams({'onHand': '$current'})
          : (breach ? 'reorder_point_warning'.trParams({'minStock': '$minStock'}) : null),
    );
  }

  @override
  String? validateLine(StockLine line) {
    final current = line.onHandIn(line.warehouse.value);
    final qty = line.enteredQty.value;
    if (!line.increase.value && current != null && qty != null && qty > current) {
      return 'validation_exceeds_on_hand'.trParams({'qty': '$current'});
    }
    return null;
  }

  String get _reason => reasonController.text.trim();

  @override
  Map<String, List<Map<String, dynamic>>> buildRequestBody() => {
        'adjustments': [
          for (final line in lines)
            {
              ...line.baseRow(),
              'warehouseCode': line.warehouse.value!.code,
              'adjustmentType': line.increase.value ? 'INCREASE' : 'DECREASE',
              'quantity': line.enteredQty.value,
              'reason': _reason,
            },
        ],
      };

  @override
  Future<void> submitDirectLine(StockLine line) =>
      adjustDirect(line, increase: line.increase.value, reason: _reason);
}
