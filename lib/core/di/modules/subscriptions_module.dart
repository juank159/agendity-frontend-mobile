import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:login_signup/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_status_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/create_paid_subscription_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/get_all_plans_usecase.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class SubscriptionsModule {
  static Future<void> init() async {
    print('Inicializando SubscriptionsModule...');

    try {
      // DataSource
      if (!Get.isRegistered<SubscriptionRemoteDataSource>()) {
        print('Registrando SubscriptionRemoteDataSource');
        Get.put<SubscriptionRemoteDataSource>(
          SubscriptionRemoteDataSource(
            dio: Get.find<Dio>(),
            localStorage: Get.find<LocalStorage>(),
          ),
          permanent: true,
        );
      }

      // Repository
      if (!Get.isRegistered<SubscriptionRepository>()) {
        print('Registrando SubscriptionRepository');
        Get.put<SubscriptionRepository>(
          SubscriptionRepositoryImpl(
            remoteDataSource: Get.find<SubscriptionRemoteDataSource>(),
          ),
          permanent: true,
        );
      }

      // Use Cases
      if (!Get.isRegistered<CheckSubscriptionStatusUseCase>()) {
        print('Registrando CheckSubscriptionStatusUseCase');
        Get.put<CheckSubscriptionStatusUseCase>(
          CheckSubscriptionStatusUseCase(
            Get.find<SubscriptionRepository>(),
          ),
          permanent: true,
        );
      }

      if (!Get.isRegistered<GetAllPlansUseCase>()) {
        print('Registrando GetAllPlansUseCase');
        Get.put<GetAllPlansUseCase>(
          GetAllPlansUseCase(
            Get.find<SubscriptionRepository>(),
          ),
          permanent: true,
        );
      }

      if (!Get.isRegistered<CreatePaidSubscriptionUseCase>()) {
        print('Registrando CreatePaidSubscriptionUseCase');
        Get.put<CreatePaidSubscriptionUseCase>(
          CreatePaidSubscriptionUseCase(
            Get.find<SubscriptionRepository>(),
          ),
          permanent: true,
        );
      }

      print('SubscriptionsModule inicializado correctamente');
    } catch (e) {
      print('Error al inicializar SubscriptionsModule: $e');
      rethrow;
    }
  }
}