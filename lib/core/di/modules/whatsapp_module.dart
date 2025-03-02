// lib/core/di/modules/whatsapp_module.dart
import 'package:get/get.dart';
import '../../../features/whatsapp/data/datasources/whatsapp_remote_datasource.dart';
import '../../../features/whatsapp/data/repositories/whatsapp_repository_impl.dart';
import '../../../features/whatsapp/domain/repositories/whatsapp_repository.dart';
import '../../../features/whatsapp/domain/usecases/get_whatsapp_config_usecase.dart';
import '../../../features/whatsapp/domain/usecases/save_whatsapp_config_usecase.dart';
import '../../../features/whatsapp/domain/usecases/send_test_message_usecase.dart';
import '../../../features/whatsapp/domain/usecases/send_message_usecase.dart';
import '../../../features/whatsapp/presentation/bindings/whatsapp_binding.dart';
import '../../../shared/local_storage/local_storage.dart';
import '../../../core/network/network_info.dart';

class WhatsappModule {
  static Future<void> init() async {
    // Dependencias básicas que deben estar disponibles
    if (!Get.isRegistered<LocalStorage>()) {
      throw Exception('LocalStorage not initialized');
    }

    if (!Get.isRegistered<NetworkInfo>()) {
      // Si no está registrado, regístralo
      Get.put(NetworkInfoImpl(connectionChecker: Get.find()));
    }

    // Registrar data source
    final remoteDataSource = WhatsappRemoteDataSourceImpl(
      dio: Get.find(),
      localStorage: Get.find(),
    );
    Get.put<WhatsappRemoteDataSource>(remoteDataSource);

    // Registrar repository
    final repository = WhatsappRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: Get.find(),
    );
    Get.put<WhatsappRepository>(repository);

    // Registrar casos de uso
    Get.put(GetWhatsappConfigUseCase(repository));
    Get.put(SaveWhatsappConfigUseCase(repository));
    Get.put(SendTestMessageUseCase(repository));
    Get.put(SendMessageUseCase(repository));

    // Registrar el binding
    Get.lazyPut(() => WhatsappBinding());

    print('WhatsApp module initialized successfully');
  }
}
