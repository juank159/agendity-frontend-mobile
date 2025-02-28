// lib/features/whatsapp/presentation/bindings/whatsapp_binding.dart
import 'package:get/get.dart';
import '../../data/datasources/whatsapp_remote_datasource.dart';
import '../../data/repositories/whatsapp_repository_impl.dart';
import '../../domain/repositories/whatsapp_repository.dart';
import '../../domain/usecases/get_whatsapp_config_usecase.dart';
import '../../domain/usecases/save_whatsapp_config_usecase.dart';
import '../../domain/usecases/send_test_message_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../controllers/whatsapp_controller.dart';
import '../../../../core/network/network_info.dart';
import '../../../../shared/local_storage/local_storage.dart';

class WhatsappBinding implements Bindings {
  @override
  void dependencies() {
    // Data Source
    Get.lazyPut<WhatsappRemoteDataSource>(
      () => WhatsappRemoteDataSourceImpl(
        dio: Get.find(),
        localStorage: Get.find<LocalStorage>(),
      ),
    );

    // Repository
    Get.lazyPut<WhatsappRepository>(
      () => WhatsappRepositoryImpl(
        remoteDataSource: Get.find<WhatsappRemoteDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
    );

    // Use Cases
    Get.lazyPut<GetWhatsappConfigUseCase>(
      () => GetWhatsappConfigUseCase(Get.find<WhatsappRepository>()),
    );

    Get.lazyPut<SaveWhatsappConfigUseCase>(
      () => SaveWhatsappConfigUseCase(Get.find<WhatsappRepository>()),
    );

    Get.lazyPut<SendTestMessageUseCase>(
      () => SendTestMessageUseCase(Get.find<WhatsappRepository>()),
    );

    Get.lazyPut<SendMessageUseCase>(
      () => SendMessageUseCase(Get.find<WhatsappRepository>()),
    );

    // Controller
    Get.lazyPut<WhatsappController>(
      () => WhatsappController(
        getWhatsappConfigUseCase: Get.find<GetWhatsappConfigUseCase>(),
        saveWhatsappConfigUseCase: Get.find<SaveWhatsappConfigUseCase>(),
        sendTestMessageUseCase: Get.find<SendTestMessageUseCase>(),
        sendMessageUseCase: Get.find<SendMessageUseCase>(),
      ),
      fenix: true,
    );
  }
}
