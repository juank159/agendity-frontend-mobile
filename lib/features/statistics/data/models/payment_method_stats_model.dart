import '../../domain/entities/payment_method_stats_entity.dart';

class PaymentMethodStatsModel extends PaymentMethodStatsEntity {
  PaymentMethodStatsModel({
    required super.method,
    required super.methodType,
    required super.count,
    required super.total,
    required super.average,
    required super.percentage,
  });

  factory PaymentMethodStatsModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodStatsModel(
      method: json['method'] as String,
      methodType: json['method_type'] as String,
      count: json['count'] as int,
      total: (json['total'] as num).toDouble(),
      average: (json['average'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}
