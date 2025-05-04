import 'package:login_signup/features/statistics/domain/entities/employee_stats_entity.dart';

import '../../domain/entities/payment_stats_entity.dart';
import '../../domain/entities/payment_comparison_entity.dart';
import '../../domain/entities/payment_method_stats_entity.dart';
import '../../domain/entities/professional_stats_entity.dart';
import '../../domain/entities/service_stats_entity.dart';
import '../../domain/entities/client_stats_entity.dart';
import '../../domain/entities/top_client_entity.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../datasources/statistics_remote_datasource.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsRemoteDataSource remoteDataSource;

  StatisticsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PaymentStatsEntity> getPaymentStats(
      DateTime startDate, DateTime endDate) async {
    return await remoteDataSource.getPaymentStats(startDate, endDate);
  }

  @override
  Future<PaymentComparisonEntity> getPaymentComparison(
      DateTime startDate, DateTime endDate) async {
    return await remoteDataSource.getPaymentComparison(startDate, endDate);
  }

  @override
  Future<List<PaymentMethodStatsEntity>> getPaymentStatsByMethod(
      DateTime startDate, DateTime endDate) async {
    return await remoteDataSource.getPaymentStatsByMethod(startDate, endDate);
  }

  @override
  Future<List<ProfessionalStatsEntity>> getPaymentStatsByProfessional(
      DateTime startDate, DateTime endDate) async {
    return await remoteDataSource.getPaymentStatsByProfessional(
        startDate, endDate);
  }

  @override
  Future<List<ServiceStatsEntity>> getPaymentStatsByService(
      DateTime startDate, DateTime endDate) async {
    return await remoteDataSource.getPaymentStatsByService(startDate, endDate);
  }

  @override
  Future<List<ClientStatsEntity>> getPaymentStatsByClient(
      DateTime startDate, DateTime endDate,
      {int limit = 10}) async {
    return await remoteDataSource.getPaymentStatsByClient(startDate, endDate,
        limit: limit);
  }

  @override
  Future<List<TopClientEntity>> getTopClients(
      DateTime startDate, DateTime endDate,
      {int limit = 5}) async {
    return await remoteDataSource.getTopClients(startDate, endDate,
        limit: limit);
  }

  @override
  Future<EmployeeStatsEntity> getEmployeeStats(
      DateTime startDate, DateTime endDate) async {
    try {
      final employeeStats =
          await remoteDataSource.getEmployeeStats(startDate, endDate);
      return employeeStats;
    } catch (e) {
      throw Exception('Error getting employee stats: $e');
    }
  }
}
