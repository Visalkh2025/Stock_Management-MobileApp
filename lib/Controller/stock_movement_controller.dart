import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Controller/stock_form_controller.dart';
import 'package:stock_management/Controller/stock_line.dart';
import 'package:stock_management/Model/lookup_models.dart';

/// Which way stock is moving — drives every label/color/icon difference
/// between the Stock In and Stock Out screens built from this one
/// controller (see [StockMovementScreen], [Routes.stockIn]/[Routes.stockOut]).
enum StockMovementDirection { stockIn, stockOut }

extension StockMovementDirectionX on StockMovementDirection {
  bool get isIn => this == StockMovementDirection.stockIn;

  // Internal type label — matched by string equality elsewhere (e.g.
  // ReportsController._typeOrder and ReportsScreen._typeLabelKeys) and
  // stored as RequestItemData.typeLabel — never translate this one.
  String get title => isIn ? 'Stock In' : 'Stock Out';

  // Display-only translation of `title`, for the screen header — reuses
  // the same keys as Home's header Stock In/Out buttons.
  String get displayTitle => isIn ? 'stock_in'.tr : 'stock_out'.tr;

  String get ctaLabel => isIn ? 'action_confirm_stock_in'.tr : 'action_confirm_stock_out'.tr;
  String get detailsCardTitle => isIn ? 'section_stock_in_details'.tr : 'section_stock_out_details'.tr;
  String get reasonHint => isIn ? 'hint_stock_in_reason'.tr : 'hint_stock_out_reason'.tr;
  IconData get icon => isIn ? Icons.call_made_rounded : Icons.call_received_rounded;
}

/// Backs both the Stock In and Stock Out screens, reached from Home's header buttons (see HomeController.stockIn/stockOut).
class StockMovementController extends StockFormController {
  // Read from Get.arguments (set by HomeController.stockIn/stockOut) instead
  // of a constructor param — same pattern RequestDetailController uses for
  // its `request`.
  late final StockMovementDirection direction = Get.arguments as StockMovementDirection;

  @override
  String get requestType => direction.isIn ? 'STOCK_IN' : 'STOCK_OUT';

  @override
  bool get needsApproval => !can(Perm.stockAdjust);

  @override
  bool get productFirst => true;

  @override
  LookupOption? incomingWarehouseOf(StockLine line) => direction.isIn ? line.warehouse.value : null;

  /// Stock In: any warehouse. Stock Out: only warehouses that hold the product.
  @override
  List<LookupOption> warehouseOptionsFor(StockLine line) {
    if (direction.isIn || line.product.value == null) return warehouses;
    return [for (final (w, _) in storedWarehouses(line, inStockOnly: true)) w];
  }

  @override
  LineImpact? impactOf(StockLine line) {
    final product = line.product.value;
    final current = line.onHandIn(line.warehouse.value);
    if (product == null || current == null) return null;
    final qty = line.enteredQty.value;
    final after = qty == null ? null : (direction.isIn ? current + qty : current - qty);
    final exceeds = !direction.isIn && qty != null && qty > current;
    final minStock = product.minStock;
    final breach = !direction.isIn && !exceeds && after != null && minStock != null && after <= minStock;
    return LineImpact(
      leftLabel: 'stat_current'.tr,
      leftValue: '$current',
      rightLabel: 'stat_after'.tr,
      rightValue: after == null ? '—' : '$after',
      tone: direction.isIn ? ImpactTone.positive : ((breach || exceeds) ? ImpactTone.danger : ImpactTone.neutral),
      warning: exceeds
          ? 'exceeds_on_hand_warning'.trParams({'onHand': '$current'})
          : (breach ? 'reorder_point_warning'.trParams({'minStock': '$minStock'}) : null),
    );
  }

  @override
  String? validateLine(StockLine line) {
    final current = line.onHandIn(line.warehouse.value);
    final qty = line.enteredQty.value;
    if (!direction.isIn && current != null && qty != null && qty > current) {
      return 'validation_exceeds_on_hand'.trParams({'qty': '$current'});
    }
    return null;
  }

  String get _reason {
    final text = reasonController.text.trim();
    return text.isEmpty ? direction.title : text;
  }

  @override
  Map<String, List<Map<String, dynamic>>> buildRequestBody() => {
        'stock': [
          for (final line in lines)
            {
              ...line.baseRow(),
              'warehouseCode': line.warehouse.value!.code,
              'quantity': line.enteredQty.value,
              'reason': _reason,
            },
        ],
      };

  @override
  Future<void> submitDirectLine(StockLine line) => adjustDirect(line, increase: direction.isIn, reason: _reason, movementType: direction.isIn ? 'IN' : 'OUT');
}
