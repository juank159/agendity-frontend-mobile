import '../entities/payment_method_stats_entity.dart';
import '../repositories/statistics_repository.dart';

class GetPaymentStatsByMethodUseCase {
  final StatisticsRepository repository;

  GetPaymentStatsByMethodUseCase(this.repository);

  Future<List<PaymentMethodStatsEntity>> call(
      DateTime startDate, DateTime endDate) {
    return repository.getPaymentStatsByMethod(startDate, endDate);
  }
}
