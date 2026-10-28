import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:login_signup/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:login_signup/features/settings/domain/repositories/settings_repository.dart';
import 'package:login_signup/features/settings/domain/usecases/get_business_settings_usecase.dart';
import 'package:login_signup/features/settings/domain/usecases/update_business_time_zone_usecase.dart';

/// Datasource, repositorio y use cases de la configuración del negocio
/// (ARQUITECTURA §4; zona horaria, D-15). El binding de la ruta (FP)
/// registra solo el controller.
abstract final class SettingsDependencies {
  static void init() {
    Get.lazyPut<SettingsRemoteDataSource>(
      () => SettingsRemoteDataSourceImpl(Get.find<Dio>(tag: apiClientTag)),
      fenix: true,
    );
    Get.lazyPut<SettingsRepository>(
      () => SettingsRepositoryImpl(
        remote: Get.find<SettingsRemoteDataSource>(),
        session: Get.find<SessionService>(),
      ),
      fenix: true,
    );
    Get.lazyPut(() => GetBusinessSettingsUseCase(Get.find<SettingsRepository>()),
        fenix: true);
    Get.lazyPut(
        () => UpdateBusinessTimeZoneUseCase(Get.find<SettingsRepository>()),
        fenix: true);
  }
}
