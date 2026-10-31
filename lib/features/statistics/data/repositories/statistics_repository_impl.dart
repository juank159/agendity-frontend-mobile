import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/features/statistics/data/local/local_stats.dart';
import 'package:login_signup/features/statistics/data/local/statistics_local_datasource.dart';
import 'package:login_signup/features/statistics/data/models/commission_settlement_model.dart';
import 'package:login_signup/features/statistics/data/models/employee_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/payment_comparison_model.dart';
import 'package:login_signup/features/statistics/data/models/payment_method_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/payment_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/professional_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/service_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/top_client_model.dart';
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

/// Estadísticas (10.02c, D-18): con conexión, **el servidor manda**; sin
/// ella (`NetworkFailure`) se calculan en local con las mismas cuentas
/// (`LocalStats`) sobre lo sincronizado. Las de ingresos necesitan los pagos,
/// que solo recibe el Owner: para el Employee sin conexión se devuelve el
/// `NetworkFailure`. La liquidación de comisiones sí: la del Employee, solo
/// la suya. Sin failures propios: 403 → `ForbiddenFailure`, 400 →
/// `ValidationFailure` y red → `NetworkFailure` ya los da `safeCall`.
class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsRemoteDataSource _remote;

  /// `null` = solo red (sin cálculo local).
  final OfflineStore? _store;
  final StatisticsLocalDataSource _local;

  StatisticsRepositoryImpl(this._remote,
      {OfflineStore? store,
      StatisticsLocalDataSource local = const StatisticsLocalDataSource()})
      : _store = store,
        _local = local;

  /// Pide al servidor; si no hay red, calcula en local con [offline]
  /// (`null` del cálculo = no se puede: queda el failure de red).
  Future<Either<Failure, T>> _serverOr<T>(
    Future<Either<Failure, T>> online,
    Future<T?> Function(LocalStats stats, bool isOwner, String? userId)
        offline,
  ) async {
    final result = await online;
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    final store = _store;
    if (failure is! NetworkFailure || store == null) return result;
    final local = await safeCall<T?>(() async {
      final db = await store.database();
      final userId = await store.databases.currentUserId();
      return offline(await _local.load(db), await _local.isOwner(db, userId),
          userId);
    });
    return local.fold(
        Left.new, (value) => value == null ? Left(failure) : Right(value));
  }

  @override
  Future<Either<Failure, PaymentStatsEntity>> getPaymentStats(
          StatsRange range) =>
      _serverOr(
          safeCall(
              () async => (await _remote.getPaymentStats(range)).toEntity()),
          (stats, owner, _) async => owner
              ? PaymentStatsModel.fromJson(
                      stats.paymentStats(range.start, range.end))
                  .toEntity()
              : null);

  @override
  Future<Either<Failure, PaymentComparisonEntity>> getPaymentComparison(
          StatsRange range) =>
      _serverOr(
          safeCall(() async =>
              (await _remote.getPaymentComparison(range)).toEntity()),
          (stats, owner, _) async => owner
              ? PaymentComparisonModel.fromJson(
                      stats.comparison(range.start, range.end))
                  .toEntity()
              : null);

  @override
  Future<Either<Failure, List<PaymentMethodStatsEntity>>>
      getPaymentStatsByMethod(StatsRange range) => _serverOr(
          safeCall(() async => (await _remote.getPaymentStatsByMethod(range))
              .map((m) => m.toEntity())
              .toList()),
          (stats, owner, _) async => owner
              ? [
                  for (final row in stats.byMethod(range.start, range.end))
                    PaymentMethodStatsModel.fromJson(row).toEntity(),
                ]
              : null);

  @override
  Future<Either<Failure, List<ProfessionalStatsEntity>>>
      getPaymentStatsByProfessional(StatsRange range) => _serverOr(
          safeCall(() async =>
              (await _remote.getPaymentStatsByProfessional(range))
                  .map((m) => m.toEntity())
                  .toList()),
          (stats, owner, _) async => owner
              ? [
                  for (final row
                      in stats.byProfessional(range.start, range.end))
                    ProfessionalStatsModel.fromJson(row).toEntity(),
                ]
              : null);

  @override
  Future<Either<Failure, List<ServiceStatsEntity>>> getPaymentStatsByService(
          StatsRange range) =>
      _serverOr(
          safeCall(() async => (await _remote.getPaymentStatsByService(range))
              .map((m) => m.toEntity())
              .toList()),
          (stats, owner, _) async => owner
              ? [
                  for (final row in stats.byService(range.start, range.end))
                    ServiceStatsModel.fromJson(row).toEntity(),
                ]
              : null);

  @override
  Future<Either<Failure, List<TopClientEntity>>> getTopClients(StatsRange range,
          {required int limit}) =>
      _serverOr(
          safeCall(() async => (await _remote.getTopClients(range, limit: limit))
              .map((m) => m.toEntity())
              .toList()),
          (stats, owner, _) async => owner
              ? [
                  for (final row in stats.topClients(range.start, range.end,
                      limit: limit))
                    TopClientModel.fromJson(row).toEntity(),
                ]
              : null);

  @override
  Future<Either<Failure, EmployeeStatsEntity>> getEmployeeStats(
          StatsRange range,
          {String? professionalId}) =>
      _serverOr(
          safeCall(() async => (await _remote.getEmployeeStats(range,
                  professionalId: professionalId))
              .toEntity()),
          (stats, owner, _) async => owner && professionalId != null
              ? EmployeeStatsModel.fromJson(stats.employeeStats(
                      range.start, range.end, professionalId))
                  .toEntity()
              : null);

  @override
  Future<Either<Failure, CommissionSettlement>> getCommissionSettlement(
          StatsRange range,
          {String? professionalId}) =>
      _serverOr(
          safeCall(() => _remote.getCommissionSettlement(range,
              professionalId: professionalId)),
          (stats, owner, userId) async {
        // El Employee: solo la suya (pedir la de otro → nada en local).
        if (!owner && professionalId != null && professionalId != userId) {
          return null;
        }
        return CommissionSettlementModel.fromJson(stats.commissions(
            range.start, range.end,
            professionalId: owner ? professionalId : userId));
      });
}
