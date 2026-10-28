import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/features/payments/data/datasources/payment_remote_datasource.dart';
import 'package:login_signup/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';
import 'package:login_signup/features/payments/domain/usecases/create_payment_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_active_custom_payment_methods_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_appointment_balance_usecase.dart';

/// Datasource, repositorio y use cases de pagos (ARQUITECTURA §4).
/// El controller lo registra `AppointmentsBinding` (abre el diálogo de pago).
abstract final class PaymentsDependencies {
  static void init() {
    Get.lazyPut<PaymentRemoteDataSource>(
      () => PaymentRemoteDataSourceImpl(Get.find<Dio>(tag: apiClientTag)),
      fenix: true,
    );
    Get.lazyPut<PaymentRepository>(
      () => PaymentRepositoryImpl(Get.find<PaymentRemoteDataSource>()),
      fenix: true,
    );
    Get.lazyPut(() => CreatePaymentUseCase(Get.find<PaymentRepository>()),
        fenix: true);
    Get.lazyPut(
        () => GetActiveCustomPaymentMethodsUseCase(
            Get.find<PaymentRepository>()),
        fenix: true);
    Get.lazyPut(
        () => GetAppointmentBalanceUseCase(Get.find<PaymentRepository>()),
        fenix: true);
  }
}
