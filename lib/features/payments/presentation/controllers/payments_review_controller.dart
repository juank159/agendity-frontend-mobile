import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/payments/domain/entities/payment_review_item.dart';
import 'package:login_signup/features/payments/domain/usecases/get_payments_in_review_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/refund_payment_usecase.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// "Pagos por revisar" (10.03, solo Owner): pagos registrados sin conexión
/// que al sincronizar no cabían. Se resuelven con un reembolso.
class PaymentsReviewController extends GetxController {
  final GetPaymentsInReviewUseCase _getInReview;
  final RefundPaymentUseCase _refund;

  PaymentsReviewController({
    required GetPaymentsInReviewUseCase getPaymentsInReviewUseCase,
    required RefundPaymentUseCase refundPaymentUseCase,
  })  : _getInReview = getPaymentsInReviewUseCase,
        _refund = refundPaymentUseCase;

  final items = <PaymentReviewItem>[].obs;
  final isLoading = false.obs;
  final error = Rxn<Failure>();
  final refundingId = RxnString();
  Worker? _worker;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<SyncController>()) {
      _worker = Get.find<SyncController>().onDataChanged(load);
    }
    load();
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    final result = await _getInReview(NoParams());
    isLoading.value = false;
    result.fold((failure) => error.value = failure, items.assignAll);
  }

  Future<void> refreshFromServer() async {
    if (Get.isRegistered<SyncController>()) {
      await Get.find<SyncController>().syncNow();
    }
    await load();
  }

  /// Registra el reembolso. `true` si se guardó (también sin conexión).
  Future<bool> refund(PaymentReviewItem item,
      {required double amount, required String reason}) async {
    if (refundingId.value != null) return false;
    refundingId.value = item.payment.id;
    final result = await _refund(
        RefundPaymentParams(payment: item.payment, amount: amount, reason: reason));
    refundingId.value = null;
    return result.fold<Future<bool>>((failure) async {
      if (failure is ValidationFailure) {
        AppSnackbar.warning(failure.message, title: 'Revisa el reembolso');
      } else {
        AppSnackbar.error(failure.message, title: 'No se registró');
      }
      return false;
    }, (_) async {
      AppSnackbar.success('Reembolso registrado', title: 'Listo');
      await load();
      return true;
    });
  }
}
