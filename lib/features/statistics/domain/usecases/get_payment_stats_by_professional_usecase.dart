import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/statistics/domain/entities/professional_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:login_signup/features/statistics/domain/usecases/stats_use_case.dart';

/// Ingresos netos por profesional (solo Owner).
class GetPaymentStatsByProfessionalUseCase
    extends StatsUseCase<List<ProfessionalStatsEntity>, StatsRange> {
  final StatisticsRepository repository;

  GetPaymentStatsByProfessionalUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProfessionalStatsEntity>>> fetch(
          StatsRange params) =>
      repository.getPaymentStatsByProfessional(params);
}
