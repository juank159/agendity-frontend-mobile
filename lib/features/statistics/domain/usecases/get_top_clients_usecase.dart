import '../entities/top_client_entity.dart';
import '../repositories/statistics_repository.dart';

class GetTopClientsUseCase {
  final StatisticsRepository repository;

  GetTopClientsUseCase(this.repository);

  Future<List<TopClientEntity>> call(DateTime startDate, DateTime endDate,
      {int limit = 5}) {
    return repository.getTopClients(startDate, endDate, limit: limit);
  }
}
