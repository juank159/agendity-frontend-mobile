import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/failures/statistics_failures.dart';

/// Rango + tope de resultados (rankings de clientes).
class StatsRankingParams implements StatsQuery {
  @override
  final StatsRange range;
  final int limit;

  const StatsRankingParams(this.range, {required this.limit});
}

/// Rango + profesional (solo lo usa el Owner; el Employee ve las suyas).
class EmployeeStatsParams implements StatsQuery {
  @override
  final StatsRange range;
  final String? professionalId;

  const EmployeeStatsParams(this.range, {this.professionalId});
}

/// Base de los use cases de estadísticas: valida la consulta antes de llamar
/// al backend (un rango invertido o un límite < 1 serían un 400 o un
/// resultado vacío engañoso) y delega en [fetch].
abstract class StatsUseCase<T, P extends StatsQuery> extends UseCase<T, P> {
  @override
  Future<Either<Failure, T>> call(P params) async {
    if (!params.range.isValid) {
      return const Left(InvalidStatsQueryFailure(
          message: InvalidStatsQueryFailure.invalidRangeMessage));
    }
    if (params is StatsRankingParams && params.limit < 1) {
      return const Left(InvalidStatsQueryFailure(
          message: InvalidStatsQueryFailure.invalidLimitMessage));
    }
    return fetch(params);
  }

  Future<Either<Failure, T>> fetch(P params);
}
