import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Controller/request_controller.dart';
import 'package:stock_management/Model/request_models.dart';

/// Static demo form — no API yet.
class NewRequestController extends GetxController {
  final productController = TextEditingController();
  final skuController = TextEditingController();
  final quantityController = TextEditingController();
  final supplierController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  void save() {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final product = productController.text.trim();
    final sku = skuController.text.trim();
    final qty = quantityController.text.trim();
    final supplier = supplierController.text.trim();
    final productLabel = sku.isEmpty ? product : '$product ($sku)';
    final detail = '${qty}x $productLabel${supplier.isEmpty ? '' : ' • Supplier: $supplier'}';

    if (!Get.isRegistered<RequestController>()) {
      Get.put(RequestController(), permanent: true);
    }
    final requestController = Get.find<RequestController>();
    requestController.addRequest(
      RequestItemData(
        requesterName: 'Visal Khem',
        typeLabel: 'Purchase Order',
        requestId: '#REQ-${1042 + requestController.totalCount}',
        detail: detail,
        submittedAgo: 'time_just_now'.tr,
        status: RequestStatus.pending,
      ),
    );

    Get.back();
  }

  @override
  void onClose() {
    productController.dispose();
    skuController.dispose();
    quantityController.dispose();
    supplierController.dispose();
    super.onClose();
  }
}
