import '../entities/payment_comparison_entity.dart';
import '../repositories/statistics_repository.dart';

class GetPaymentComparisonUseCase {
  final StatisticsRepository repository;

  GetPaymentComparisonUseCase(this.repository);

  Future<PaymentComparisonEntity> call(DateTime startDate, DateTime endDate) {
    return repository.getPaymentComparison(startDate, endDate);
  }
}
