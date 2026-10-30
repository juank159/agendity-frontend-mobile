import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/statistics/domain/entities/commission_settlement.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:login_signup/features/statistics/domain/usecases/stats_use_case.dart';

/// Liquidación de comisiones del periodo (D-16, 8.02). Owner: todos los
/// profesionales, o uno con `professionalId`; Employee: siempre la suya
/// (pedir la de otro → `ForbiddenFailure`).
class GetCommissionSettlementUseCase
    extends StatsUseCase<CommissionSettlement, EmployeeStatsParams> {
  final StatisticsRepository repository;

  GetCommissionSettlementUseCase(this.repository);

  @override
  Future<Either<Failure, CommissionSettlement>> fetch(
          EmployeeStatsParams params) =>
      repository.getCommissionSettlement(params.range,
          professionalId: params.professionalId);
}
