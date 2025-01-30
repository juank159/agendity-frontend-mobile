// services_module.dart
import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/usecases/delete_service_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_service_usecase.dart';
import '../../../features/services/domain/usecases/get_services_usecase.dart';
import '../../../features/services/domain/usecases/create_service_usecase.dart';
import '../../../features/services/domain/repositories/services_repository.dart';
import '../../../features/services/data/datasources/services_remote_datasource.dart';
import '../../../features/services/data/repositories/services_repository_impl.dart';
import '../../../shared/local_storage/local_storage.dart';
import 'package:dio/dio.dart';

class ServicesModule {
  static Future<void> init() async {
    try {
      // Inicializa el datasource si es necesario
      if (!Get.isRegistered<ServicesRemoteDataSource>()) {
        Get.put<ServicesRemoteDataSource>(
          ServicesRemoteDataSource(
            dio: Get.find<Dio>(),
            localStorage: Get.find<LocalStorage>(),
          ),
          permanent: true,
        );
      }

      // Inicializa el repositorio
      if (!Get.isRegistered<ServicesRepository>()) {
        Get.put<ServicesRepository>(
          ServicesRepositoryImpl(
            remoteDataSource: Get.find(),
          ),
          permanent: true,
        );
      }

      // Inicializa los casos de uso
      if (!Get.isRegistered<GetServicesUseCase>()) {
        Get.put<GetServicesUseCase>(
          GetServicesUseCase(
            Get.find(),
          ),
          permanent: true,
        );
      }

      // Añadir registro del CreateServiceUseCase
      if (!Get.isRegistered<CreateServiceUseCase>()) {
        Get.put<CreateServiceUseCase>(
          CreateServiceUseCase(
            Get.find(),
          ),
          permanent: true,
        );
      }

      // actualizar servicio
      if (!Get.isRegistered<UpdateServiceUseCase>()) {
        Get.put<UpdateServiceUseCase>(
          UpdateServiceUseCase(Get.find()),
          permanent: true,
        );
      }

      if (!Get.isRegistered<DeleteServiceUseCase>()) {
        Get.put<DeleteServiceUseCase>(
          DeleteServiceUseCase(Get.find()),
          permanent: true,
        );
      }
    } catch (e) {
      print('Error initializing ServicesModule: $e');
      rethrow;
    }
  }

  static void reset() {
    // Método para limpiar las dependencias cuando sea necesario
    if (Get.isRegistered<CreateServiceUseCase>()) {
      Get.delete<CreateServiceUseCase>();
    }
    if (Get.isRegistered<GetServicesUseCase>()) {
      Get.delete<GetServicesUseCase>();
    }
    if (Get.isRegistered<ServicesRepository>()) {
      Get.delete<ServicesRepository>();
    }
    if (Get.isRegistered<ServicesRemoteDataSource>()) {
      Get.delete<ServicesRemoteDataSource>();
    }
  }
}
