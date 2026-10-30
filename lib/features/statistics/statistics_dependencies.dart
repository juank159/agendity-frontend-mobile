import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/features/statistics/data/datasources/statistics_remote_datasource.dart';
import 'package:login_signup/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_commission_settlement_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_employee_stats_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_comparison_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_method_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_professional_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_service_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_top_clients_usecase.dart';

/// Datasource, repositorio y use cases de estadísticas (ARQUITECTURA §4).
/// El controller lo registra `StatisticsBinding`.
abstract final class StatisticsDependencies {
  static void init() {
    Get.lazyPut<StatisticsRemoteDataSource>(
      () => StatisticsRemoteDataSourceImpl(Get.find<Dio>(tag: apiClientTag)),
      fenix: true,
    );
    Get.lazyPut<StatisticsRepository>(
      () => StatisticsRepositoryImpl(Get.find<StatisticsRemoteDataSource>()),
      fenix: true,
    );

    Get.lazyPut(() => GetPaymentStatsUseCase(Get.find<StatisticsRepository>()),
        fenix: true);
    Get.lazyPut(
        () => GetPaymentComparisonUseCase(Get.find<StatisticsRepository>()),
        fenix: true);
    Get.lazyPut(
        () => GetPaymentStatsByMethodUseCase(Get.find<StatisticsRepository>()),
        fenix: true);
    Get.lazyPut(
        () => GetPaymentStatsByProfessionalUseCase(
            Get.find<StatisticsRepository>()),
        fenix: true);
    Get.lazyPut(
        () => GetPaymentStatsByServiceUseCase(Get.find<StatisticsRepository>()),
        fenix: true);
    Get.lazyPut(() => GetTopClientsUseCase(Get.find<StatisticsRepository>()),
        fenix: true);
    Get.lazyPut(
        () => GetCommissionSettlementUseCase(Get.find<StatisticsRepository>()),
        fenix: true);
    Get.lazyPut(() => GetEmployeeStatsUseCase(Get.find<StatisticsRepository>()),
        fenix: true);
  }
}
