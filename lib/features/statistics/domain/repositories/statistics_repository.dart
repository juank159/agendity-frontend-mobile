import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/statistics/domain/entities/client_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/employee_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_comparison_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_method_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/professional_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/service_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/entities/top_client_entity.dart';

/// Estadísticas de ingresos (netos: cobrado − reembolsado) por días del
/// negocio. Todo es solo Owner (`ForbiddenFailure` para el Employee) salvo
/// [getEmployeeStats]. Un rango sin pagos no es error: ceros o listas vacías.
abstract class StatisticsRepository {
  Future<Either<Failure, PaymentStatsEntity>> getPaymentStats(StatsRange range);

  Future<Either<Failure, PaymentComparisonEntity>> getPaymentComparison(
      StatsRange range);

  Future<Either<Failure, List<PaymentMethodStatsEntity>>>
      getPaymentStatsByMethod(StatsRange range);

  Future<Either<Failure, List<ProfessionalStatsEntity>>>
      getPaymentStatsByProfessional(StatsRange range);

  Future<Either<Failure, List<ServiceStatsEntity>>> getPaymentStatsByService(
      StatsRange range);

  Future<Either<Failure, List<ClientStatsEntity>>> getPaymentStatsByClient(
      StatsRange range,
      {required int limit});

  Future<Either<Failure, List<TopClientEntity>>> getTopClients(StatsRange range,
      {required int limit});

  /// El Employee recibe siempre las suyas ([professionalId] se ignora). El
  /// Owner debe indicar [professionalId]; sin él, `ValidationFailure` (400).
  Future<Either<Failure, EmployeeStatsEntity>> getEmployeeStats(
      StatsRange range,
      {String? professionalId});
}
