import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:login_signup/features/statistics/domain/usecases/stats_use_case.dart';

/// Ingresos netos del período (solo Owner).
class GetPaymentStatsUseCase
    extends StatsUseCase<PaymentStatsEntity, StatsRange> {
  final StatisticsRepository repository;

  GetPaymentStatsUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentStatsEntity>> fetch(StatsRange params) =>
      repository.getPaymentStats(params);
}
