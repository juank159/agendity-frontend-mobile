import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/features/whatsapp/data/datasources/whatsapp_remote_datasource.dart';
import 'package:login_signup/features/whatsapp/data/repositories/whatsapp_repository_impl.dart';
import 'package:login_signup/features/whatsapp/domain/repositories/whatsapp_repository.dart';
import 'package:login_signup/features/whatsapp/domain/usecases/get_whatsapp_config_usecase.dart';
import 'package:login_signup/features/whatsapp/domain/usecases/save_whatsapp_config_usecase.dart';
import 'package:login_signup/features/whatsapp/domain/usecases/send_test_message_usecase.dart';

/// Datasource, repositorio y use cases de whatsapp (ARQUITECTURA §4).
/// El binding de la ruta registra solo el controller.
abstract final class WhatsappDependencies {
  static void init() {
    Get.lazyPut<WhatsappRemoteDataSource>(
      () => WhatsappRemoteDataSourceImpl(Get.find<Dio>(tag: apiClientTag)),
      fenix: true,
    );
    Get.lazyPut<WhatsappRepository>(
      () => WhatsappRepositoryImpl(Get.find<WhatsappRemoteDataSource>()),
      fenix: true,
    );
    Get.lazyPut(() => GetWhatsappConfigUseCase(Get.find<WhatsappRepository>()),
        fenix: true);
    Get.lazyPut(() => SaveWhatsappConfigUseCase(Get.find<WhatsappRepository>()),
        fenix: true);
    Get.lazyPut(() => SendTestMessageUseCase(Get.find<WhatsappRepository>()),
        fenix: true);
  }
}
