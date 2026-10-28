import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/statistics/domain/entities/employee_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:login_signup/features/statistics/domain/usecases/stats_use_case.dart';

/// Estadísticas de un profesional: las propias para el Employee; el Owner indica `professionalId`.
class GetEmployeeStatsUseCase
    extends StatsUseCase<EmployeeStatsEntity, EmployeeStatsParams> {
  final StatisticsRepository repository;

  GetEmployeeStatsUseCase(this.repository);

  @override
  Future<Either<Failure, EmployeeStatsEntity>> fetch(
          EmployeeStatsParams params) =>
      repository.getEmployeeStats(params.range,
          professionalId: params.professionalId);
}
