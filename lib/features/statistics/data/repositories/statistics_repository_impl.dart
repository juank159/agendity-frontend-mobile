import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/features/statistics/data/datasources/statistics_remote_datasource.dart';
import 'package:login_signup/features/statistics/domain/entities/commission_settlement.dart';
import 'package:login_signup/features/statistics/domain/entities/employee_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_comparison_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_method_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/professional_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/service_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/entities/top_client_entity.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';

/// Sin failures propios: 403 → `ForbiddenFailure`, 400 → `ValidationFailure`
/// y red → `NetworkFailure` ya los da `safeCall`.
class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsRemoteDataSource _remote;

  StatisticsRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaymentStatsEntity>> getPaymentStats(
          StatsRange range) =>
      safeCall(() async => (await _remote.getPaymentStats(range)).toEntity());

  @override
  Future<Either<Failure, PaymentComparisonEntity>> getPaymentComparison(
          StatsRange range) =>
      safeCall(
          () async => (await _remote.getPaymentComparison(range)).toEntity());

  @override
  Future<Either<Failure, List<PaymentMethodStatsEntity>>>
      getPaymentStatsByMethod(StatsRange range) =>
          safeCall(() async => (await _remote.getPaymentStatsByMethod(range))
              .map((m) => m.toEntity())
              .toList());

  @override
  Future<Either<Failure, List<ProfessionalStatsEntity>>>
      getPaymentStatsByProfessional(StatsRange range) => safeCall(() async =>
          (await _remote.getPaymentStatsByProfessional(range))
              .map((m) => m.toEntity())
              .toList());

  @override
  Future<Either<Failure, List<ServiceStatsEntity>>> getPaymentStatsByService(
          StatsRange range) =>
      safeCall(() async => (await _remote.getPaymentStatsByService(range))
          .map((m) => m.toEntity())
          .toList());

  @override
  Future<Either<Failure, List<TopClientEntity>>> getTopClients(StatsRange range,
          {required int limit}) =>
      safeCall(() async => (await _remote.getTopClients(range, limit: limit))
          .map((m) => m.toEntity())
          .toList());

  @override
  Future<Either<Failure, EmployeeStatsEntity>> getEmployeeStats(
          StatsRange range,
          {String? professionalId}) =>
      safeCall(() async => (await _remote.getEmployeeStats(range,
              professionalId: professionalId))
          .toEntity());

  @override
  Future<Either<Failure, CommissionSettlement>> getCommissionSettlement(
          StatsRange range,
          {String? professionalId}) =>
      safeCall(() => _remote.getCommissionSettlement(range,
          professionalId: professionalId));
}
