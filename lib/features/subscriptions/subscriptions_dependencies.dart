import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:login_signup/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_limits_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/create_paid_subscription_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/get_all_plans_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/get_current_subscription_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/refresh_subscription_status_usecase.dart';

/// Datasource, repositorio y use cases de suscripciones (ARQUITECTURA §4).
/// `CheckSubscriptionLimitsUseCase` lo usa también appointments.
abstract final class SubscriptionsDependencies {
  static void init() {
    Get.lazyPut<SubscriptionRemoteDataSource>(
      () => SubscriptionRemoteDataSourceImpl(Get.find<Dio>(tag: apiClientTag)),
      fenix: true,
    );
    Get.lazyPut<SubscriptionRepository>(
      () =>
          SubscriptionRepositoryImpl(Get.find<SubscriptionRemoteDataSource>()),
      fenix: true,
    );

    Get.lazyPut(() => GetAllPlansUseCase(Get.find<SubscriptionRepository>()),
        fenix: true);
    Get.lazyPut(
        () => GetCurrentSubscriptionUseCase(Get.find<SubscriptionRepository>()),
        fenix: true);
    Get.lazyPut(
        () =>
            CheckSubscriptionLimitsUseCase(Get.find<SubscriptionRepository>()),
        fenix: true);
    Get.lazyPut(
        () => CreatePaidSubscriptionUseCase(Get.find<SubscriptionRepository>()),
        fenix: true);
    Get.lazyPut(
        () => RefreshSubscriptionStatusUseCase(
            Get.find<SubscriptionRepository>()),
        fenix: true);
  }
}
