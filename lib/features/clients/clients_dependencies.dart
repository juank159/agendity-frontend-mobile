import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/features/clients/data/datasources/clients_local_datasource.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/clients/data/repositories/client_repository_impl.dart';
import 'package:login_signup/features/clients/data/sync/clients_sync_handler.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';
import 'package:login_signup/features/clients/domain/usecases/create_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/delete_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/get_client_by_id_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/get_clients_page_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/import_clients_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/update_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/upload_client_image_usecase.dart';

/// Datasources, repositorio, use cases y handler de sincronización de
/// clientes (ARQUITECTURA §4, 10.02). Los controllers los registran los
/// bindings (clientes y citas).
abstract final class ClientsDependencies {
  static void init() {
    Get.lazyPut<ClientsRemoteDataSource>(
      () => ClientsRemoteDataSourceImpl(Get.find<Dio>(tag: apiClientTag)),
      fenix: true,
    );
    Get.lazyPut<ClientsRepository>(
      () => ClientsRepositoryImpl(
        remote: Get.find<ClientsRemoteDataSource>(),
        store: Get.find<OfflineStore>(),
      ),
      fenix: true,
    );
    // 10.02: los cambios del feed `clients` y las operaciones `client.*`.
    Get.find<SyncEngine>().register(
        ClientsSyncHandler(const ClientsLocalDataSource(),
            Get.find<ClientsRemoteDataSource>()));

    Get.lazyPut(() => GetClientsPageUseCase(Get.find<ClientsRepository>()),
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
