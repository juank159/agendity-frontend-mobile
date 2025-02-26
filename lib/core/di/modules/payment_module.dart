import 'package:get/get.dart';
import 'package:login_signup/features/payments/data/datasources/payment_remote_datasource.dart';
import 'package:login_signup/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';
import 'package:login_signup/features/payments/domain/usecases/create_payment_usecase.dart';

class PaymentModule {
  static Future<void> init() async {
    try {
      // Limpiar instancias previas si existen
      _resetModule();

      // Payment DataSources
      Get.put<PaymentRemoteDataSource>(
        PaymentRemoteDataSource(
          dio: Get.find(),
          localStorage: Get.find(),
        ),
        permanent: true,
      );

      // Payment Repositories
      Get.put<PaymentRepository>(
        PaymentRepositoryImpl(
          remoteDataSource: Get.find(),
        ),
        permanent: true,
      );

      // Payment UseCases
      Get.put<CreatePaymentUseCase>(
        CreatePaymentUseCase(Get.find()),
        permanent: true,
      );

      print('Payment module initialized successfully');
    } catch (e) {
      print('Error initializing PaymentModule: $e');
      rethrow;
    }
  }

  static void _resetModule() {
    if (Get.isRegistered<PaymentRemoteDataSource>()) {
      Get.delete<PaymentRemoteDataSource>(force: true);
    }
    if (Get.isRegistered<PaymentRepository>()) {
      Get.delete<PaymentRepository>(force: true);
    }
    if (Get.isRegistered<CreatePaymentUseCase>()) {
      Get.delete<CreatePaymentUseCase>(force: true);
    }
  }
}
