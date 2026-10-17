import 'package:stock_management/Config/api_config.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/master_list_controller.dart';
import 'package:stock_management/Model/master_data_models.dart';
import 'package:stock_management/Services/master_data_crud.dart';

/// Manage > Brands — the list comes from `GET /brands`; Add/Edit is [BrandFormController].
class BrandController extends MasterListController<BrandData> {
  @override
  late final MasterDataCrud<BrandData> crud = MasterDataCrud<BrandData>(
    path: ApiConfig.brands,
    fromJson: BrandData.fromJson,
  );

  @override
  String get formRoute => Routes.brandForm;
}
