import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/statistics/domain/entities/employee_stats_entity.dart';

/// DTO de `GET /payments/employee-stats`:
/// `{summary: {...}, by_service: [...], daily_evolution: [{date: "YYYY-MM-DD"}]}`.
/// Sin pagos en el rango: resumen en 0 y listas vacías.
/// - `by_service[].count` son citas (2.28).
/// - `daily_evolution[]`: `payment_count` (= `count`) y `appointment_count`.
class EmployeeStatsModel {
  final EmployeeStatsSummary summary;
  final List<EmployeeServiceStats> byService;
  final List<EmployeeDailyStats> dailyEvolution;

  const EmployeeStatsModel({
    required this.summary,
    required this.byService,
    required this.dailyEvolution,
  });

  factory EmployeeStatsModel.fromJson(Map<String, dynamic> json) {
    final summary = JsonRead.asMap(json['summary']) ?? const {};
    return EmployeeStatsModel(
      summary: EmployeeStatsSummary(
        totalAmount: JsonRead.asDouble(summary['total_amount']),
        paymentCount: JsonRead.asInt(summary['payment_count']),
        appointmentCount: JsonRead.asInt(summary['appointment_count']),
        averagePerPayment: JsonRead.asDouble(summary['average_per_payment']),
      ),
      byService: JsonRead.asMapList(json['by_service'])
          .map((item) => EmployeeServiceStats(
                serviceId: JsonRead.asString(item['service_id']),
                serviceName: JsonRead.asString(item['service_name']),
                appointmentCount: JsonRead.asInt(item['count']),
                total: JsonRead.asDouble(item['total']),
              ))
          .toList(),
      dailyEvolution: [
        // Un día ilegible se descarta en vez de romper todo el informe.
        for (final item in JsonRead.asMapList(json['daily_evolution']))
          if (DateCodec.tryDecodeDay(item['date']) case final day?)
            EmployeeDailyStats(
              day: day,
              total: JsonRead.asDouble(item['total']),
              paymentCount:
                  JsonRead.asInt(item['payment_count'] ?? item['count']),
              appointmentCount: JsonRead.asInt(item['appointment_count']),
            ),
      ],
    );
  }

  EmployeeStatsEntity toEntity() => EmployeeStatsEntity(
        summary: summary,
        byService: List.unmodifiable(byService),
        dailyEvolution: List.unmodifiable(dailyEvolution),
      );
}
