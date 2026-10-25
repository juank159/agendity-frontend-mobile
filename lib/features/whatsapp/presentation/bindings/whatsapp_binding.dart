import 'package:get/get.dart';
import '../../domain/usecases/get_whatsapp_config_usecase.dart';
import '../../domain/usecases/save_whatsapp_config_usecase.dart';
import '../../domain/usecases/send_test_message_usecase.dart';
import '../controllers/whatsapp_controller.dart';

/// Solo el controller: datasource, repositorio y use cases los registra
/// `WhatsappDependencies` (features/whatsapp/whatsapp_dependencies.dart).
class WhatsappBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WhatsappController>(
      () => WhatsappController(
        getWhatsappConfigUseCase: Get.find<GetWhatsappConfigUseCase>(),
        saveWhatsappConfigUseCase: Get.find<SaveWhatsappConfigUseCase>(),
        sendTestMessageUseCase: Get.find<SendTestMessageUseCase>(),
      ),
      fenix: true,
    );
  }
}
