import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_comparison_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:login_signup/features/statistics/domain/usecases/stats_use_case.dart';

/// Período frente al anterior de igual duración (solo Owner).
class GetPaymentComparisonUseCase
    extends StatsUseCase<PaymentComparisonEntity, StatsRange> {
  final StatisticsRepository repository;

  GetPaymentComparisonUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentComparisonEntity>> fetch(StatsRange params) =>
      repository.getPaymentComparison(params);
}
