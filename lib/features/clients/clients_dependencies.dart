import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/clients/data/repositories/client_repository_impl.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';
import 'package:login_signup/features/clients/domain/usecases/create_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/delete_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/get_all_clients_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/get_client_by_id_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/get_clients_page_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/import_clients_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/update_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/upload_client_image_usecase.dart';

/// Datasource, repositorio y use cases de clientes (ARQUITECTURA §4). Los
/// controllers los registran los bindings (clientes y citas).
abstract final class ClientsDependencies {
  static void init() {
    Get.lazyPut<ClientsRemoteDataSource>(
      () => ClientsRemoteDataSourceImpl(Get.find<Dio>(tag: apiClientTag)),
      fenix: true,
    );
    Get.lazyPut<ClientsRepository>(
      () => ClientsRepositoryImpl(Get.find<ClientsRemoteDataSource>()),
      fenix: true,
    );

    Get.lazyPut(() => GetClientsPageUseCase(Get.find<ClientsRepository>()),
        fenix: true);
    Get.lazyPut(() => GetAllClientsUseCase(Get.find<ClientsRepository>()),
        fenix: true);
    Get.lazyPut(() => GetClientByIdUseCase(Get.find<ClientsRepository>()),
        fenix: true);
    Get.lazyPut(() => CreateClientUseCase(Get.find<ClientsRepository>()),
        fenix: true);
    Get.lazyPut(() => UpdateClientUseCase(Get.find<ClientsRepository>()),
        fenix: true);
    Get.lazyPut(() => DeleteClientUseCase(Get.find<ClientsRepository>()),
        fenix: true);
    Get.lazyPut(() => ImportClientsUseCase(Get.find<ClientsRepository>()),
        fenix: true);
    Get.lazyPut(() => UploadClientImageUseCase(Get.find<ClientsRepository>()),
        fenix: true);
  }
}
