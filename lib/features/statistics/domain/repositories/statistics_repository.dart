import '../entities/payment_stats_entity.dart';
import '../entities/payment_comparison_entity.dart';
import '../entities/payment_method_stats_entity.dart';
import '../entities/professional_stats_entity.dart';
import '../entities/service_stats_entity.dart';
import '../entities/client_stats_entity.dart';
import '../entities/top_client_entity.dart';

abstract class StatisticsRepository {
  Future<PaymentStatsEntity> getPaymentStats(
      DateTime startDate, DateTime endDate);

  Future<PaymentComparisonEntity> getPaymentComparison(
      DateTime startDate, DateTime endDate);

  Future<List<PaymentMethodStatsEntity>> getPaymentStatsByMethod(
      DateTime startDate, DateTime endDate);

  Future<List<ProfessionalStatsEntity>> getPaymentStatsByProfessional(
      DateTime startDate, DateTime endDate);

  Future<List<ServiceStatsEntity>> getPaymentStatsByService(
      DateTime startDate, DateTime endDate);

  Future<List<ClientStatsEntity>> getPaymentStatsByClient(
      DateTime startDate, DateTime endDate,
      {int limit = 10});

  Future<List<TopClientEntity>> getTopClients(
      DateTime startDate, DateTime endDate,
      {int limit = 5});
}
