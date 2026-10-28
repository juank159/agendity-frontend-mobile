import 'package:get/get.dart';
import 'package:login_signup/features/subscriptions/presentation/controllers/subscription_controller.dart';

/// Solo el controller: los use cases los registra `SubscriptionsDependencies`.
class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SubscriptionController>()) {
      Get.put<SubscriptionController>(
        SubscriptionController(
          checkSubscriptionLimitsUseCase: Get.find(),
          getAllPlansUseCase: Get.find(),
          createPaidSubscriptionUseCase: Get.find(),
          getCurrentSubscriptionUseCase: Get.find(),
        ),
      );
    }
  }
}
