import 'package:dio/dio.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/features/statistics/data/models/client_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/employee_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/payment_comparison_model.dart';
import 'package:login_signup/features/statistics/data/models/payment_method_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/payment_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/professional_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/service_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/top_client_model.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';

/// Rutas `/payments/stats*` (solo Owner) y `/payments/employee-stats` (Owner
/// con `professionalId` o Employee). `startDate`/`endDate` = `yyyy-MM-dd`, días
/// completos del negocio. Los errores (400/403, red) salen como `DioException`
/// y los traduce `safeCall` en el repositorio.
abstract class StatisticsRemoteDataSource {
  Future<PaymentStatsModel> getPaymentStats(StatsRange range);

  Future<PaymentComparisonModel> getPaymentComparison(StatsRange range);

  Future<List<PaymentMethodStatsModel>> getPaymentStatsByMethod(
      StatsRange range);

  Future<List<ProfessionalStatsModel>> getPaymentStatsByProfessional(
      StatsRange range);

  Future<List<ServiceStatsModel>> getPaymentStatsByService(StatsRange range);

  Future<List<ClientStatsModel>> getPaymentStatsByClient(StatsRange range,
      {required int limit});

  Future<List<TopClientModel>> getTopClients(StatsRange range,
      {required int limit});

  Future<EmployeeStatsModel> getEmployeeStats(StatsRange range,
      {String? professionalId});
}

class StatisticsRemoteDataSourceImpl implements StatisticsRemoteDataSource {
  final Dio _dio;

  /// Debe ser el Dio `tag: apiClientTag` (token y errores del núcleo).
  StatisticsRemoteDataSourceImpl(this._dio);

  @override
  Future<PaymentStatsModel> getPaymentStats(StatsRange range) async =>
      PaymentStatsModel.fromJson(await _getObject('/payments/stats', range));

  @override
  Future<PaymentComparisonModel> getPaymentComparison(StatsRange range) async =>
      PaymentComparisonModel.fromJson(
          await _getObject('/payments/stats/comparison', range));

  @override
  Future<List<PaymentMethodStatsModel>> getPaymentStatsByMethod(
          StatsRange range) async =>
      (await _getList('/payments/stats/by-method', range))
          .map(PaymentMethodStatsModel.fromJson)
          .toList();

  @override
  Future<List<ProfessionalStatsModel>> getPaymentStatsByProfessional(
          StatsRange range) async =>
      (await _getList('/payments/stats/by-professional', range))
          .map(ProfessionalStatsModel.fromJson)
          .toList();

  @override
  Future<List<ServiceStatsModel>> getPaymentStatsByService(
          StatsRange range) async =>
      (await _getList('/payments/stats/by-service', range))
          .map(ServiceStatsModel.fromJson)
          .toList();

  @override
  Future<List<ClientStatsModel>> getPaymentStatsByClient(StatsRange range,
          {required int limit}) async =>
      (await _getList('/payments/stats/by-client', range, {'limit': limit}))
          .map(ClientStatsModel.fromJson)
          .toList();

  @override
  Future<List<TopClientModel>> getTopClients(StatsRange range,
          {required int limit}) async =>
      (await _getList('/payments/stats/top-clients', range, {'limit': limit}))
          .map(TopClientModel.fromJson)
          .toList();

  @override
  Future<EmployeeStatsModel> getEmployeeStats(StatsRange range,
          {String? professionalId}) async =>
      EmployeeStatsModel.fromJson(await _getObject(
        '/payments/employee-stats',
        range,
        {if (professionalId != null) 'professionalId': professionalId},
      ));

  Future<Map<String, dynamic>> _getObject(String path, StatsRange range,
      [Map<String, Object> extra = const {}]) async {
    final response = await _dio.get<Map<String, dynamic>>(path,
        queryParameters: _query(range, extra));
    return response.data!;
  }

  Future<List<Map<String, dynamic>>> _getList(String path, StatsRange range,
      [Map<String, Object> extra = const {}]) async {
    final response = await _dio.get<List<dynamic>>(path,
        queryParameters: _query(range, extra));
    return response.data!.cast<Map<String, dynamic>>();
  }

  static Map<String, Object> _query(
          StatsRange range, Map<String, Object> extra) =>
      {
        'startDate': DateCodec.encodeDay(range.start),
        'endDate': DateCodec.encodeDay(range.end),
        ...extra,
      };
}
