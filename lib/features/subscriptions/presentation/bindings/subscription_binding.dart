import 'package:get/get.dart';
import 'package:login_signup/features/subscriptions/presentation/controllers/subscription_controller.dart';

/// Solo el controller: los use cases los registra `SubscriptionsDependencies`.
/// Lo comparten la ruta de planes y la de la webview de pago (`fenix`).
class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubscriptionController>(
      () => SubscriptionController(
        getCurrentSubscriptionUseCase: Get.find(),
        getAllPlansUseCase: Get.find(),
        createPaidSubscriptionUseCase: Get.find(),
        refreshSubscriptionStatusUseCase: Get.find(),
      ),
      fenix: true,
    );
  }
}
