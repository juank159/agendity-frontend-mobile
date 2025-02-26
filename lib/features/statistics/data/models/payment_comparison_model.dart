import '../../domain/entities/payment_comparison_entity.dart';

class PaymentComparisonModel extends PaymentComparisonEntity {
  PaymentComparisonModel({
    required super.currentPeriod,
    required super.previousPeriod,
    required super.change,
  });

  factory PaymentComparisonModel.fromJson(Map<String, dynamic> json) {
    return PaymentComparisonModel(
      currentPeriod: PeriodStatsModel.fromJson(json['current_period']),
      previousPeriod: PeriodStatsModel.fromJson(json['previous_period']),
      change: ChangeStatsModel.fromJson(json['change']),
    );
  }
}

class PeriodStatsModel extends PeriodStatsEntity {
  PeriodStatsModel({
    required super.startDate,
    required super.endDate,
    required super.totalAmount,
    required super.paymentCount,
    required super.averageAmount,
  });

  factory PeriodStatsModel.fromJson(Map<String, dynamic> json) {
    return PeriodStatsModel(
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentCount: json['payment_count'] as int,
      averageAmount: (json['average_amount'] as num).toDouble(),
    );
  }
}

class ChangeStatsModel extends ChangeStatsEntity {
  ChangeStatsModel({
    required super.amountDifference,
    required super.amountPercentage,
    required super.countDifference,
    required super.countPercentage,
    required super.averageDifference,
    required super.averagePercentage,
  });

  factory ChangeStatsModel.fromJson(Map<String, dynamic> json) {
    return ChangeStatsModel(
      amountDifference: (json['amount_difference'] as num).toDouble(),
      amountPercentage: (json['amount_percentage'] as num).toDouble(),
      countDifference: json['count_difference'] as int,
      countPercentage: (json['count_percentage'] as num).toDouble(),
      averageDifference: (json['average_difference'] as num).toDouble(),
      averagePercentage: (json['average_percentage'] as num).toDouble(),
    );
  }
}
