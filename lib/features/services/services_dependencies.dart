import 'package:get/get.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/features/services/data/repositories/categories_repository_impl.dart';
import 'package:login_signup/features/services/data/repositories/services_repository_impl.dart';
import 'package:login_signup/features/services/data/sync/catalog_sync.dart';
import 'package:login_signup/features/services/domain/repositories/categories_repository.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';
import 'package:login_signup/features/services/domain/usecases/create_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/create_service_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/delete_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/delete_service_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_all_services_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_categories_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_offered_by_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_status_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_service_usecase.dart';

/// Repositorios, use cases y handlers de sincronización de servicios y
/// categorías (ARQUITECTURA §4; sin conexión desde 10.02b). Los controllers
/// los registran los bindings de la feature.
abstract final class ServicesDependencies {
  static void init() {
    Get.lazyPut<ServicesRepository>(
      () => ServicesRepositoryImpl(Get.find<OfflineStore>()),
      fenix: true,
    );
    Get.lazyPut<CategoriesRepository>(
      () => CategoriesRepositoryImpl(Get.find<OfflineStore>()),
      fenix: true,
    );

    CatalogSync.handlers().forEach(Get.find<SyncEngine>().register);

    Get.lazyPut(() => GetServicesUseCase(Get.find<ServicesRepository>()),
        fenix: true);
    Get.lazyPut(() => GetAllServicesUseCase(Get.find<ServicesRepository>()),
        fenix: true);
    Get.lazyPut(
        () => GetServicesOfferedByUseCase(Get.find<ServicesRepository>()),
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
