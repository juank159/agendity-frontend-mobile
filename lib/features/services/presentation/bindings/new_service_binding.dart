// lib/features/services/presentation/bindings/new_service_binding.dart
// import 'package:get/get.dart';
// import 'package:login_signup/features/services/presentation/controller/new_service_controller.dart';

// class NewServiceBinding extends Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<NewServiceController>(
//       () => NewServiceController(),
//       fenix: true, // Esto mantiene la instancia viva mientras se use
//     );
//   }
// }

// lib/features/services/presentation/bindings/new_service_binding.dart
import 'package:get/get.dart';
import 'package:login_signup/features/services/data/datasources/categories_remote_datasource.dart';
import 'package:login_signup/features/services/data/repositories/categories_repository_impl.dart';
import 'package:login_signup/features/services/domain/repositories/categories_repository.dart';
import 'package:login_signup/features/services/domain/usecases/get_categories_usecase.dart';
import 'package:login_signup/features/services/presentation/controller/new_service_controller.dart';

class NewServiceBinding extends Bindings {
  @override
  void dependencies() {
    // Data Sources
    Get.lazyPut<CategoriesRemoteDataSource>(
      () => CategoriesRemoteDataSource(
        dio: Get.find(),
        localStorage: Get.find(),
      ),
    );

    // Repositories
    Get.lazyPut<CategoriesRepository>(
      () => CategoriesRepositoryImpl(
        remoteDataSource: Get.find<CategoriesRemoteDataSource>(),
      ),
    );

    // Use Cases
    Get.lazyPut<GetCategoriesUseCase>(
      () => GetCategoriesUseCase(Get.find<CategoriesRepository>()),
    );

    // Controller
    Get.lazyPut<NewServiceController>(
      () => NewServiceController(
        getCategoriesUseCase: Get.find<GetCategoriesUseCase>(),
      ),
      fenix: true,
    );
  }
}
