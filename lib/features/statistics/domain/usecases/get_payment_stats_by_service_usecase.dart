import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/statistics/domain/entities/service_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:login_signup/features/statistics/domain/usecases/stats_use_case.dart';

/// Uso de servicios en citas pagadas (solo Owner).
class GetPaymentStatsByServiceUseCase
    extends StatsUseCase<List<ServiceStatsEntity>, StatsRange> {
  final StatisticsRepository repository;

  GetPaymentStatsByServiceUseCase(this.repository);

  @override
  Future<Either<Failure, List<ServiceStatsEntity>>> fetch(StatsRange params) =>
      repository.getPaymentStatsByService(params);
}
