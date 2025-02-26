import '../entities/service_stats_entity.dart';
import '../repositories/statistics_repository.dart';

class GetPaymentStatsByServiceUseCase {
  final StatisticsRepository repository;

  GetPaymentStatsByServiceUseCase(this.repository);

  Future<List<ServiceStatsEntity>> call(DateTime startDate, DateTime endDate) {
    return repository.getPaymentStatsByService(startDate, endDate);
  }
}
