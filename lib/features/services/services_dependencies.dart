import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/features/services/data/datasources/categories_remote_datasource.dart';
import 'package:login_signup/features/services/data/datasources/services_remote_datasource.dart';
import 'package:login_signup/features/services/data/repositories/categories_repository_impl.dart';
import 'package:login_signup/features/services/data/repositories/services_repository_impl.dart';
import 'package:login_signup/features/services/domain/repositories/categories_repository.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';
import 'package:login_signup/features/services/domain/usecases/create_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/create_service_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/delete_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/delete_service_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_categories_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_status_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_service_usecase.dart';

/// Datasources, repositorios y use cases de servicios y categorías
/// (ARQUITECTURA §4). Los controllers los registran los bindings de la feature.
abstract final class ServicesDependencies {
  static void init() {
    Get.lazyPut<ServicesRemoteDataSource>(
      () => ServicesRemoteDataSourceImpl(Get.find<Dio>(tag: apiClientTag)),
      fenix: true,
    );
    Get.lazyPut<CategoriesRemoteDataSource>(
      () => CategoriesRemoteDataSourceImpl(Get.find<Dio>(tag: apiClientTag)),
      fenix: true,
    );
    Get.lazyPut<ServicesRepository>(
      () => ServicesRepositoryImpl(Get.find<ServicesRemoteDataSource>()),
      fenix: true,
    );
    Get.lazyPut<CategoriesRepository>(
      () => CategoriesRepositoryImpl(Get.find<CategoriesRemoteDataSource>()),
      fenix: true,
    );

    Get.lazyPut(() => GetServicesUseCase(Get.find<ServicesRepository>()),
        fenix: true);
    Get.lazyPut(() => CreateServiceUseCase(Get.find<ServicesRepository>()),
        fenix: true);
    Get.lazyPut(() => UpdateServiceUseCase(Get.find<ServicesRepository>()),
        fenix: true);
    Get.lazyPut(() => DeleteServiceUseCase(Get.find<ServicesRepository>()),
        fenix: true);

    Get.lazyPut(() => GetCategoriesUseCase(Get.find<CategoriesRepository>()),
        fenix: true);
    Get.lazyPut(() => CreateCategoryUseCase(Get.find<CategoriesRepository>()),
        fenix: true);
    Get.lazyPut(() => UpdateCategoryUseCase(Get.find<CategoriesRepository>()),
        fenix: true);
    Get.lazyPut(
        () => UpdateCategoryStatusUseCase(Get.find<CategoriesRepository>()),
        fenix: true);
    Get.lazyPut(() => DeleteCategoryUseCase(Get.find<CategoriesRepository>()),
        fenix: true);
  }
}
