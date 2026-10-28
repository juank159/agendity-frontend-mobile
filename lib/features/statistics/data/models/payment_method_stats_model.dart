import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_method_stats_entity.dart';

/// DTO de un elemento de `GET /payments/stats/by-method` (`PaymentMethodStats`).
/// Un método propio llega con `method_type: 'CUSTOM'`, su nombre en `method`
/// y `custom_payment_method_id`.
class PaymentMethodStatsModel {
  final String method;
  final String? methodType;
  final String? customPaymentMethodId;
  final int count;
  final double total;
  final double average;
  final double percentage;

  const PaymentMethodStatsModel({
    required this.method,
    this.methodType,
    this.customPaymentMethodId,
    required this.count,
    required this.total,
    required this.average,
    required this.percentage,
  });

  factory PaymentMethodStatsModel.fromJson(Map<String, dynamic> json) =>
      PaymentMethodStatsModel(
        method: JsonRead.asString(json['method']),
        methodType: JsonRead.asOptionalString(json['method_type']),
        customPaymentMethodId:
            JsonRead.asOptionalString(json['custom_payment_method_id']),
        count: JsonRead.asInt(json['count']),
        total: JsonRead.asDouble(json['total']),
        average: JsonRead.asDouble(json['average']),
        percentage: JsonRead.asDouble(json['percentage']),
      );

  PaymentMethodStatsEntity toEntity() {
    final type = customPaymentMethodId != null
        ? PaymentMethodType.custom
        : PaymentMethodType.fromApi(methodType);
    return PaymentMethodStatsEntity(
        method: method,
        // El nombre de un método propio no es un código: no se interpreta.
        paymentMethod: type == PaymentMethodType.custom
            ? null
            : PaymentMethod.fromApi(method),
        methodType: type,
        customPaymentMethodId: customPaymentMethodId,
        count: count,
        total: total,
        average: average,
        percentage: percentage);
  }
}
