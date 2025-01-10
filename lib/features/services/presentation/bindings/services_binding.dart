// lib/features/services/presentation/bindings/services_binding.dart
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';
import '../../data/datasources/services_remote_datasource.dart';
import '../../data/repositories/services_repository_impl.dart';
import '../../domain/repositories/services_repository.dart';
import '../controller/services_controller.dart';

class ServicesBinding extends Bindings {
  @override
  void dependencies() {
    // Data Sources
    Get.put(
      ServicesRemoteDataSource(
        dio: Get.find<Dio>(),
        localStorage: Get.find<LocalStorage>(),
      ),
    );

    // Repositories
    Get.put<ServicesRepository>(
      ServicesRepositoryImpl(
        remoteDataSource: Get.find<ServicesRemoteDataSource>(),
      ),
    );

    // Controllers
    Get.put(
      ServicesController(
        repository: Get.find<ServicesRepository>(),
      ),
    );
  }
}
