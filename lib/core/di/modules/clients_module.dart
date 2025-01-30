import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/clients/data/repositories/client_repository_impl.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';
import 'package:login_signup/features/clients/domain/usecases/clients_usecases.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class ClientsModule {
  static Future<void> init() async {
    try {
      if (!Get.isRegistered<ClientsRemoteDataSource>()) {
        Get.put<ClientsRemoteDataSource>(
          ClientsRemoteDataSource(
            dio: Get.find<Dio>(),
            localStorage: Get.find<LocalStorage>(),
          ),
          permanent: true,
        );
      }

      if (!Get.isRegistered<ClientsRepository>()) {
        Get.put<ClientsRepository>(
          ClientsRepositoryImpl(
            remoteDataSource: Get.find(),
          ),
          permanent: true,
        );
      }

      if (!Get.isRegistered<GetClientsUseCase>()) {
        Get.put<GetClientsUseCase>(
          GetClientsUseCase(Get.find()),
          permanent: true,
        );
      }

      if (!Get.isRegistered<CreateClientUseCase>()) {
        Get.put<CreateClientUseCase>(
          CreateClientUseCase(Get.find()),
          permanent: true,
        );
      }

      if (!Get.isRegistered<ImportContactsUseCase>()) {
        Get.put<ImportContactsUseCase>(
          ImportContactsUseCase(Get.find()),
          permanent: true,
        );
      }
    } catch (e) {
      print('Error initializing ClientsModule: $e');
      rethrow;
    }
  }

  static void reset() {
    if (Get.isRegistered<CreateClientUseCase>()) {
      Get.delete<CreateClientUseCase>();
    }
    if (Get.isRegistered<GetClientsUseCase>()) {
      Get.delete<GetClientsUseCase>();
    }
    if (Get.isRegistered<ImportContactsUseCase>()) {
      Get.delete<ImportContactsUseCase>();
    }
    if (Get.isRegistered<ClientsRepository>()) {
      Get.delete<ClientsRepository>();
    }
    if (Get.isRegistered<ClientsRemoteDataSource>()) {
      Get.delete<ClientsRemoteDataSource>();
    }
  }
}
