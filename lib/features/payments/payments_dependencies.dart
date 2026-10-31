import 'package:get/get.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/features/payments/data/sync/payments_sync.dart';
import 'package:login_signup/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';
import 'package:login_signup/features/payments/domain/usecases/create_payment_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_active_custom_payment_methods_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_appointment_balance_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_payments_in_review_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/refund_payment_usecase.dart';

/// Datasource, repositorio y use cases de pagos (ARQUITECTURA §4).
/// El controller lo registra `AppointmentsBinding` (abre el diálogo de pago).
abstract final class PaymentsDependencies {
  static void init() {
    Get.lazyPut<PaymentRepository>(
      () => PaymentRepositoryImpl(Get.find<OfflineStore>()),
      fenix: true,
    );
    // 10.02b: pagos (`payment.create`) y métodos propios (solo bajada).
    PaymentsSync.handlers().forEach(Get.find<SyncEngine>().register);
    Get.lazyPut(() => CreatePaymentUseCase(Get.find<PaymentRepository>()),
        fenix: true);
    Get.lazyPut(
        () => GetActiveCustomPaymentMethodsUseCase(
            Get.find<PaymentRepository>()),
        fenix: true);
    Get.lazyPut(
        () => GetAppointmentBalanceUseCase(Get.find<PaymentRepository>()),
        fenix: true);
    Get.lazyPut(
        () => GetPaymentsInReviewUseCase(Get.find<PaymentRepository>()),
        fenix: true);
    Get.lazyPut(() => RefundPaymentUseCase(Get.find<PaymentRepository>()),
        fenix: true);
  }
}
