import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_method_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:login_signup/features/statistics/domain/usecases/stats_use_case.dart';

/// Ingresos netos por método de pago (solo Owner).
class GetPaymentStatsByMethodUseCase
    extends StatsUseCase<List<PaymentMethodStatsEntity>, StatsRange> {
  final StatisticsRepository repository;

  GetPaymentStatsByMethodUseCase(this.repository);

  @override
  Future<Either<Failure, List<PaymentMethodStatsEntity>>> fetch(
          StatsRange params) =>
      repository.getPaymentStatsByMethod(params);
}
