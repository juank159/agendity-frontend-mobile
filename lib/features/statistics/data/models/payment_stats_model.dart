import '../../domain/entities/payment_stats_entity.dart';

class PaymentStatsModel extends PaymentStatsEntity {
  PaymentStatsModel({
    required super.totalAmount,
    required super.paymentCount,
    required super.averageAmount,
  });

  factory PaymentStatsModel.fromJson(Map<String, dynamic> json) {
    return PaymentStatsModel(
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentCount: json['payment_count'] as int,
      averageAmount: (json['average_amount'] as num).toDouble(),
    );
  }
}
