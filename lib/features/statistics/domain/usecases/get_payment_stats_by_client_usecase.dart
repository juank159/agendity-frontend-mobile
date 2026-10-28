import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/statistics/domain/entities/client_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:login_signup/features/statistics/domain/usecases/stats_use_case.dart';

/// Clientes por gasto neto, con frecuencia de visita (solo Owner).
class GetPaymentStatsByClientUseCase
    extends StatsUseCase<List<ClientStatsEntity>, StatsRankingParams> {
  final StatisticsRepository repository;

  GetPaymentStatsByClientUseCase(this.repository);

  @override
  Future<Either<Failure, List<ClientStatsEntity>>> fetch(
          StatsRankingParams params) =>
      repository.getPaymentStatsByClient(params.range, limit: params.limit);
}
