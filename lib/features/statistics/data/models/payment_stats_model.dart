import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_stats_entity.dart';

/// DTO de `GET /payments/stats` (`PaymentStats` del backend; importes netos).
class PaymentStatsModel {
  final double totalAmount;
  final int paymentCount;
  final double averageAmount;

  const PaymentStatsModel({
    required this.totalAmount,
    required this.paymentCount,
    required this.averageAmount,
  });

  factory PaymentStatsModel.fromJson(Map<String, dynamic> json) =>
      PaymentStatsModel(
        totalAmount: JsonRead.asDouble(json['total_amount']),
        paymentCount: JsonRead.asInt(json['payment_count']),
        averageAmount: JsonRead.asDouble(json['average_amount']),
      );

  PaymentStatsEntity toEntity() => PaymentStatsEntity(
        totalAmount: totalAmount,
        paymentCount: paymentCount,
        averageAmount: averageAmount,
      );
}
