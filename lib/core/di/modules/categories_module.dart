import 'package:get/get.dart';
import 'package:login_signup/features/services/data/datasources/categories_remote_datasource.dart';
import 'package:login_signup/features/services/data/repositories/categories_repository_impl.dart';
import 'package:login_signup/features/services/domain/repositories/categories_repository.dart';
import 'package:login_signup/features/services/domain/usecases/get_categories_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/create_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_status_usecase.dart';

class CategoriesModule {
  static Future<void> init() async {
    try {
      // Limpiar instancias previas si existen
      _resetModule();

      // Categories DataSources
      Get.put<CategoriesRemoteDataSource>(
        CategoriesRemoteDataSource(
          dio: Get.find(),
          localStorage: Get.find(),
        ),
        permanent: true,
      );

      // Categories Repositories
      Get.put<CategoriesRepository>(
        CategoriesRepositoryImpl(
          remoteDataSource: Get.find(),
        ),
        permanent: true,
      );

      // Categories UseCases
      Get.put<GetCategoriesUseCase>(
        GetCategoriesUseCase(Get.find()),
        permanent: true,
      );

      Get.put<CreateCategoryUseCase>(
        CreateCategoryUseCase(Get.find()),
        permanent: true,
      );

      Get.put<UpdateCategoryStatusUseCase>(
        UpdateCategoryStatusUseCase(Get.find()),
        permanent: true,
      );
    } catch (e) {
      print('Error initializing CategoriesModule: $e');
      rethrow;
    }
  }

  static void _resetModule() {
    if (Get.isRegistered<CategoriesRemoteDataSource>()) {
      Get.delete<CategoriesRemoteDataSource>(force: true);
    }
    if (Get.isRegistered<CategoriesRepository>()) {
      Get.delete<CategoriesRepository>(force: true);
    }
    if (Get.isRegistered<GetCategoriesUseCase>()) {
      Get.delete<GetCategoriesUseCase>(force: true);
    }
    if (Get.isRegistered<CreateCategoryUseCase>()) {
      Get.delete<CreateCategoryUseCase>(force: true);
    }
    if (Get.isRegistered<UpdateCategoryStatusUseCase>()) {
      Get.delete<UpdateCategoryStatusUseCase>(force: true);
    }
  }
}
