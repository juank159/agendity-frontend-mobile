import 'package:get/get.dart';
import 'package:login_signup/features/payments/presentation/controllers/payments_review_controller.dart';

/// "Pagos por revisar" (`/payments/review`, solo Owner).
class PaymentsReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentsReviewController>(
      () => PaymentsReviewController(
        getPaymentsInReviewUseCase: Get.find(),
        refundPaymentUseCase: Get.find(),
      ),
    );
  }
}
