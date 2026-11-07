import 'package:get/get.dart';
import 'package:stock_management/Config/permissions.dart';
import 'package:stock_management/Controller/stock_form_controller.dart';
import 'package:stock_management/Controller/stock_line.dart';
import 'package:stock_management/Model/lookup_models.dart';
import 'package:stock_management/Services/product_service.dart';

/// Reached from Home's "Transfer" quick action (see HomeController.
/// openTransfer / Routes.transfer). Moves one or more products from a source
/// warehouse to a destination warehouse. Someone with STOCK_TRANSFER (Super
/// Admin, Admin, Manager) moves the stock straight away through
/// `POST /stock-adjustments/transfer`; everyone else sends a STOCK_TRANSFER
/// request that needs an approval chain. A transfer is net-zero on total
/// on-hand, so instead of a Current -> After preview each line checks its
/// quantity against what the source warehouse actually holds.
class TransferController extends StockFormController {
  /// The source warehouse of the whole request.
  final warehouse = Rxn<LookupOption>();

  /// The destination.
  final toWarehouse = Rxn<LookupOption>();

  @override
  bool get warehousePerLine => false;

  @override
  LookupOption? incomingWarehouseOf(StockLine line) => toWarehouse.value;

  @override
  LookupOption? warehouseOf(StockLine line) => warehouse.value;

  @override
  bool requiresStock(StockLine line) => true;

  @override
  String get requestType => 'STOCK_TRANSFER';

  @override
  bool get needsApproval => !can(Perm.stockTransfer);

  /// Destination options: every warehouse except the source.
  List<LookupOption> get destinationOptions {
    final from = warehouse.value;
    return [
      for (final w in warehouses)
        if (from == null || w.code != from.code) w,
    ];
  }

  void selectSource(LookupOption? value) {
    warehouse.value = value;
    // The destination can no longer be the same warehouse.
    if (value != null && toWarehouse.value?.code == value.code) toWarehouse.value = null;
  }

  @override
  LineImpact? impactOf(StockLine line) {
    final onHand = line.onHandIn(warehouse.value);
    if (line.product.value == null || onHand == null) return null;
    final qty = line.enteredQty.value;
    final exceeds = qty != null && qty > onHand;
    return LineImpact(
      leftLabel: 'stat_on_hand'.tr,
      leftValue: '$onHand',
      rightLabel: 'stat_moving'.tr,
      rightValue: qty == null ? '—' : '$qty',
      tone: exceeds ? ImpactTone.danger : ImpactTone.neutral,
      warning: exceeds ? 'exceeds_on_hand_warning'.trParams({'onHand': '$onHand'}) : null,
    );
  }

  @override
  String? validateLine(StockLine line) {
    final onHand = line.onHandIn(warehouse.value);
    final qty = line.enteredQty.value;
    if (onHand != null && qty != null && qty > onHand) {
      return 'validation_exceeds_on_hand'.trParams({'qty': '$onHand'});
    }
    return null;
  }

  @override
  Map<String, List<Map<String, dynamic>>> buildRequestBody() => {
        'stock': [
          for (final line in lines)
            {
              ...line.baseRow(),
              'fromWarehouseCode': warehouse.value!.code,
              'toWarehouseCode': toWarehouse.value!.code,
              'quantity': line.enteredQty.value,
            },
        ],
      };

  @override
  Future<void> submitDirectLine(StockLine line) => ProductService().transferStock(
        productCode: line.product.value!.code!,
        variantCode: line.variant.value?.code,
        fromWarehouseCode: warehouse.value!.code,
        toWarehouseCode: toWarehouse.value!.code,
        quantity: line.enteredQty.value!,
      );
}
