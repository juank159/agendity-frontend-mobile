import '../entities/professional_stats_entity.dart';
import '../repositories/statistics_repository.dart';

class GetPaymentStatsByProfessionalUseCase {
  final StatisticsRepository repository;

  GetPaymentStatsByProfessionalUseCase(this.repository);

  Future<List<ProfessionalStatsEntity>> call(
      DateTime startDate, DateTime endDate) {
    return repository.getPaymentStatsByProfessional(startDate, endDate);
  }
}
