import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_method_stats_entity.dart';

/// DTO de un elemento de `GET /payments/stats/by-method` (`PaymentMethodStats`).
class PaymentMethodStatsModel {
  final String method;
  final String? methodType;
  final int count;
  final double total;
  final double average;
  final double percentage;

  const PaymentMethodStatsModel({
    required this.method,
    this.methodType,
    required this.count,
    required this.total,
    required this.average,
    required this.percentage,
  });

  factory PaymentMethodStatsModel.fromJson(Map<String, dynamic> json) =>
      PaymentMethodStatsModel(
        method: JsonRead.asString(json['method']),
        methodType: JsonRead.asOptionalString(json['method_type']),
        count: JsonRead.asInt(json['count']),
        total: JsonRead.asDouble(json['total']),
        average: JsonRead.asDouble(json['average']),
        percentage: JsonRead.asDouble(json['percentage']),
      );

  PaymentMethodStatsEntity toEntity() => PaymentMethodStatsEntity(
        method: method,
        paymentMethod: PaymentMethod.fromApi(method),
        methodType: PaymentMethodType.fromApi(methodType),
        count: count,
        total: total,
        average: average,
        percentage: percentage,
      );
}
