// lib/core/di/modules/statistics_module.dart
import 'package:get/get.dart';
import 'package:login_signup/features/statistics/data/datasources/statistics_remote_datasource.dart';
import 'package:login_signup/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_employee_stats_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_comparison_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_method_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_professional_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_service_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_client_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_top_clients_usecase.dart';

class StatisticsModule {
  static Future<void> init() async {
    try {
      // Limpiar instancias previas si existen
      _resetModule();

      // Statistics DataSources
      Get.put<StatisticsRemoteDataSource>(
        StatisticsRemoteDataSource(
          dio: Get.find(),
          localStorage: Get.find(),
        ),
        permanent: true,
      );

      // Statistics Repositories
      Get.put<StatisticsRepository>(
        StatisticsRepositoryImpl(
          remoteDataSource: Get.find(),
        ),
        permanent: true,
      );

      // Statistics UseCases
      Get.put<GetPaymentStatsUseCase>(
        GetPaymentStatsUseCase(Get.find()),
        permanent: true,
      );

      Get.put<GetPaymentComparisonUseCase>(
        GetPaymentComparisonUseCase(Get.find()),
        permanent: true,
      );

      Get.put<GetPaymentStatsByMethodUseCase>(
        GetPaymentStatsByMethodUseCase(Get.find()),
        permanent: true,
      );

      Get.put<GetPaymentStatsByProfessionalUseCase>(
        GetPaymentStatsByProfessionalUseCase(Get.find()),
        permanent: true,
      );

      Get.put<GetPaymentStatsByServiceUseCase>(
        GetPaymentStatsByServiceUseCase(Get.find()),
        permanent: true,
      );

      Get.put<GetPaymentStatsByClientUseCase>(
        GetPaymentStatsByClientUseCase(Get.find()),
        permanent: true,
      );

      Get.put<GetTopClientsUseCase>(
        GetTopClientsUseCase(Get.find()),
        permanent: true,
      );

      Get.put<GetEmployeeStatsUseCase>(
        GetEmployeeStatsUseCase(Get.find()),
        permanent: true,
      );

      print('Statistics module initialized successfully');
    } catch (e) {
      print('Error initializing StatisticsModule: $e');
      rethrow;
    }
  }

  static void _resetModule() {
    if (Get.isRegistered<StatisticsRemoteDataSource>()) {
      Get.delete<StatisticsRemoteDataSource>(force: true);
    }
    if (Get.isRegistered<StatisticsRepository>()) {
      Get.delete<StatisticsRepository>(force: true);
    }
    if (Get.isRegistered<GetPaymentStatsUseCase>()) {
      Get.delete<GetPaymentStatsUseCase>(force: true);
    }
    if (Get.isRegistered<GetPaymentComparisonUseCase>()) {
      Get.delete<GetPaymentComparisonUseCase>(force: true);
    }
    if (Get.isRegistered<GetPaymentStatsByMethodUseCase>()) {
      Get.delete<GetPaymentStatsByMethodUseCase>(force: true);
    }
    if (Get.isRegistered<GetPaymentStatsByProfessionalUseCase>()) {
      Get.delete<GetPaymentStatsByProfessionalUseCase>(force: true);
    }
    if (Get.isRegistered<GetPaymentStatsByServiceUseCase>()) {
      Get.delete<GetPaymentStatsByServiceUseCase>(force: true);
    }
    if (Get.isRegistered<GetPaymentStatsByClientUseCase>()) {
      Get.delete<GetPaymentStatsByClientUseCase>(force: true);
    }
    if (Get.isRegistered<GetTopClientsUseCase>()) {
      Get.delete<GetTopClientsUseCase>(force: true);
    }
    if (Get.isRegistered<GetEmployeeStatsUseCase>()) {
      Get.delete<GetEmployeeStatsUseCase>(force: true);
    }
  }
}
