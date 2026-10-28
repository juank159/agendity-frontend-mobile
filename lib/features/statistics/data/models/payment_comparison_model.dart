import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_comparison_entity.dart';

/// DTO de `GET /payments/stats/comparison` (`PaymentComparisonStats`).
class PaymentComparisonModel {
  final PeriodStatsModel currentPeriod;
  final PeriodStatsModel previousPeriod;
  final ChangeStatsModel change;

  const PaymentComparisonModel({
    required this.currentPeriod,
    required this.previousPeriod,
    required this.change,
  });

  /// Lanza `FormatException` si falta un período o su día de inicio o fin:
  /// sin ellos la comparación no tiene sentido (`safeCall` → `ServerFailure`).
  factory PaymentComparisonModel.fromJson(Map<String, dynamic> json) =>
      PaymentComparisonModel(
        currentPeriod:
            PeriodStatsModel.fromJson(_object(json, 'current_period')),
        previousPeriod:
            PeriodStatsModel.fromJson(_object(json, 'previous_period')),
        change: ChangeStatsModel.fromJson(
            JsonRead.asMap(json['change']) ?? const {}),
      );

  PaymentComparisonEntity toEntity() => PaymentComparisonEntity(
        currentPeriod: currentPeriod.toEntity(),
        previousPeriod: previousPeriod.toEntity(),
        change: change.toEntity(),
      );

  static Map<String, dynamic> _object(Map<String, dynamic> json, String key) =>
      JsonRead.asMap(json[key]) ??
      (throw FormatException('Comparación sin "$key"'));
}

/// Un período. `start_date`/`end_date` llegan como instantes con el offset
/// del negocio (00:00 y 23:59:59.999 de Bogotá) y se guardan como **días**
/// (`DateCodec.tryDecodeDay`): con `decode`, en otra zona el fin del período
/// caería en el día siguiente.
class PeriodStatsModel {
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final int paymentCount;
  final double averageAmount;

  const PeriodStatsModel({
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.paymentCount,
    required this.averageAmount,
  });

  factory PeriodStatsModel.fromJson(Map<String, dynamic> json) =>
      PeriodStatsModel(
        startDate: _day(json['start_date']),
        endDate: _day(json['end_date']),
        totalAmount: JsonRead.asDouble(json['total_amount']),
        paymentCount: JsonRead.asInt(json['payment_count']),
        averageAmount: JsonRead.asDouble(json['average_amount']),
      );

  PeriodStatsEntity toEntity() => PeriodStatsEntity(
        startDate: startDate,
        endDate: endDate,
        totalAmount: totalAmount,
        paymentCount: paymentCount,
        averageAmount: averageAmount,
      );

  static DateTime _day(Object? value) =>
      DateCodec.tryDecodeDay(value) ??
      (throw FormatException('Día de período inválido: $value'));
}

class ChangeStatsModel {
  final double amountDifference;
  final double amountPercentage;
  final int countDifference;
  final double countPercentage;
  final double averageDifference;
  final double averagePercentage;

  const ChangeStatsModel({
    required this.amountDifference,
    required this.amountPercentage,
    required this.countDifference,
    required this.countPercentage,
    required this.averageDifference,
    required this.averagePercentage,
  });

  factory ChangeStatsModel.fromJson(Map<String, dynamic> json) =>
      ChangeStatsModel(
        amountDifference: JsonRead.asDouble(json['amount_difference']),
        amountPercentage: JsonRead.asDouble(json['amount_percentage']),
        countDifference: JsonRead.asInt(json['count_difference']),
        countPercentage: JsonRead.asDouble(json['count_percentage']),
        averageDifference: JsonRead.asDouble(json['average_difference']),
        averagePercentage: JsonRead.asDouble(json['average_percentage']),
      );

  ChangeStatsEntity toEntity() => ChangeStatsEntity(
        amountDifference: amountDifference,
        amountPercentage: amountPercentage,
        countDifference: countDifference,
        countPercentage: countPercentage,
        averageDifference: averageDifference,
        averagePercentage: averagePercentage,
      );
}
