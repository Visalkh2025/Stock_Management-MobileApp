import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/Model/lookup_models.dart';
import 'package:stock_management/Model/stock_models.dart';
import 'package:stock_management/Services/api_exception.dart';
import 'package:stock_management/Services/master_data_service.dart';
import 'package:stock_management/Services/product_service.dart';
import 'package:stock_management/View/Components/app_button.dart';
import 'package:stock_management/View/Components/app_picker_field.dart';
import 'package:stock_management/View/Components/app_text_field.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';

/// "Stock In" for a product that already exists: new goods arrived, add
/// them to a warehouse. Sent as an INCREASE stock adjustment with the
/// reason "Restock" (needs STOCK_ADJUST).
class StockInSheet extends StatefulWidget {
  const StockInSheet({super.key, required this.product, required this.onDone});

  final StockItemData product;
  final Future<void> Function() onDone;

  @override
  State<StockInSheet> createState() => _StockInSheetState();
}

class _StockInSheetState extends State<StockInSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _service = ProductService();

  List<LookupOption> _warehouses = const [];
  LookupOption? _warehouse;
  LookupOption? _variant;
  bool _loadingWarehouses = true;
  bool _saving = false;
  String? _error;

  List<LookupOption> get _variantOptions => widget.product.variants
      .map((v) => LookupOption(id: v.id ?? v.variantCode, code: v.variantCode, name: v.variantName))
      .toList();

  @override
  void initState() {
    super.initState();
    final matched = widget.product.matchedVariantCode;
    if (matched != null) {
      for (final v in _variantOptions) {
        if (v.code == matched) _variant = v;
      }
    }
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    try {
      final list = await MasterDataService().warehouses();
      if (!mounted) return;
      setState(() {
        _warehouses = list;
        // Default to the warehouse that already holds this product.
        final existing = widget.product.warehouseStocks.isNotEmpty ? widget.product.warehouseStocks.first.warehouseCode : null;
        for (final w in list) {
          if (w.code == existing) _warehouse = w;
        }
        _loadingWarehouses = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingWarehouses = false;
      });
    }
  }

  String? _quantityValidator(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return 'validation_required'.tr;
    final qty = int.tryParse(text);
    if (qty == null || qty < 1) return 'validation_qty_min'.tr;
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final code = widget.product.code;
    if (code == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.adjustStock(
        productCode: code,
        variantCode: _variant?.code,
        warehouseCode: _warehouse!.code,
        quantity: int.parse(_quantityController.text.trim()),
        increase: true,
        reason: 'Restock',
        location: _locationController.text,
      );
      await widget.onDone();
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnackbar.success('action_stock_in_title'.tr, 'stock_in_done_message'.tr);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'action_stock_in_title'.tr,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 2),
              Text(widget.product.name, style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
              const SizedBox(height: 16),
              if (widget.product.hasVariants) ...[
                AppPickerField(
                  label: 'section_variants'.tr,
                  value: _variant,
                  options: _variantOptions,
                  required: true,
                  onChanged: (v) => setState(() => _variant = v),
                ),
                const SizedBox(height: 14),
              ],
              AppPickerField(
                label: 'field_warehouse'.tr,
                value: _warehouse,
                options: _warehouses,
                isLoading: _loadingWarehouses,
                required: true,
                prefixIcon: Icon(Icons.store_outlined, size: 20, color: AppColors.textTertiary),
                onChanged: (v) => setState(() => _warehouse = v),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'field_quantity'.tr,
                controller: _quantityController,
                hintText: 'hint_zero'.tr,
                keyboardType: TextInputType.number,
                validator: _quantityValidator,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'field_location'.tr,
                controller: _locationController,
                hintText: 'hint_location_example'.tr,
                prefixIcon: Icon(Icons.place_outlined, size: 20, color: AppColors.textTertiary),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(fontSize: 12.5, color: AppColors.danger)),
              ],
              const SizedBox(height: 18),
              AppButton(label: 'action_save'.tr, onPressed: _save, isLoading: _saving),
            ],
          ),
        ),
      ),
    );
  }
}
