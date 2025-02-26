import '../entities/payment_stats_entity.dart';
import '../repositories/statistics_repository.dart';

class GetPaymentStatsUseCase {
  final StatisticsRepository repository;

  GetPaymentStatsUseCase(this.repository);

  Future<PaymentStatsEntity> call(DateTime startDate, DateTime endDate) {
    return repository.getPaymentStats(startDate, endDate);
  }
}
