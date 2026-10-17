import 'package:stock_management/Config/api_config.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/master_list_controller.dart';
import 'package:stock_management/Model/master_data_models.dart';
import 'package:stock_management/Services/master_data_crud.dart';

/// Manage > Suppliers — the list comes from `GET /suppliers`; Add/Edit is [SupplierFormController].
class SupplierController extends MasterListController<SupplierData> {
  @override
  late final MasterDataCrud<SupplierData> crud = MasterDataCrud<SupplierData>(
    path: ApiConfig.suppliers,
    fromJson: SupplierData.fromJson,
  );

  @override
  String get formRoute => Routes.supplierForm;
}
