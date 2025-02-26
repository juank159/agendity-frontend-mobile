class PaymentComparisonEntity {
  final PeriodStatsEntity currentPeriod;
  final PeriodStatsEntity previousPeriod;
  final ChangeStatsEntity change;

  PaymentComparisonEntity({
    required this.currentPeriod,
    required this.previousPeriod,
    required this.change,
  });
}

class PeriodStatsEntity {
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final int paymentCount;
  final double averageAmount;

  PeriodStatsEntity({
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.paymentCount,
    required this.averageAmount,
  });
}

class ChangeStatsEntity {
  final double amountDifference;
  final double amountPercentage;
  final int countDifference;
  final double countPercentage;
  final double averageDifference;
  final double averagePercentage;

  ChangeStatsEntity({
    required this.amountDifference,
    required this.amountPercentage,
    required this.countDifference,
    required this.countPercentage,
    required this.averageDifference,
    required this.averagePercentage,
  });
}
