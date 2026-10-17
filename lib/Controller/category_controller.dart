import 'package:stock_management/Config/api_config.dart';
import 'package:stock_management/Config/routes/app_routes.dart';
import 'package:stock_management/Controller/master_list_controller.dart';
import 'package:stock_management/Model/master_data_models.dart';
import 'package:stock_management/Services/master_data_crud.dart';

/// Manage > Categories — the list comes from `GET /categories`; Add/Edit is [CategoryFormController].
class CategoryController extends MasterListController<CategoryData> {
  @override
  late final MasterDataCrud<CategoryData> crud = MasterDataCrud<CategoryData>(
    path: ApiConfig.categories,
    fromJson: CategoryData.fromJson,
  );

  @override
  String get formRoute => Routes.categoryForm;
}
