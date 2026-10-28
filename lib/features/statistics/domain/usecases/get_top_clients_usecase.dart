import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/statistics/domain/entities/top_client_entity.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:login_signup/features/statistics/domain/usecases/stats_use_case.dart';

/// Ranking de clientes por gasto neto (solo Owner).
class GetTopClientsUseCase
    extends StatsUseCase<List<TopClientEntity>, StatsRankingParams> {
  final StatisticsRepository repository;

  GetTopClientsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TopClientEntity>>> fetch(
          StatsRankingParams params) =>
      repository.getTopClients(params.range, limit: params.limit);
}
