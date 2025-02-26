import '../entities/client_stats_entity.dart';
import '../repositories/statistics_repository.dart';

class GetPaymentStatsByClientUseCase {
  final StatisticsRepository repository;

  GetPaymentStatsByClientUseCase(this.repository);

  Future<List<ClientStatsEntity>> call(DateTime startDate, DateTime endDate,
      {int limit = 10}) {
    return repository.getPaymentStatsByClient(startDate, endDate, limit: limit);
  }
}
