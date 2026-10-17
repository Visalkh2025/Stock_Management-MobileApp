import 'package:stock_management/Config/api_config.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/master_list_controller.dart';
import 'package:stock_management/Model/master_data_models.dart';
import 'package:stock_management/Services/master_data_crud.dart';

/// Manage > Warehouses — the list comes from `GET /warehouses`; Add/Edit is [WarehouseFormController].
class WarehouseController extends MasterListController<WarehouseData> {
  @override
  late final MasterDataCrud<WarehouseData> crud = MasterDataCrud<WarehouseData>(
    path: ApiConfig.warehouses,
    fromJson: WarehouseData.fromJson,
  );

  @override
  String get formRoute => Routes.warehouseForm;
}
