/// Período pedido frente al anterior de la misma duración
/// (`GET /payments/stats/comparison`). Importes netos.
class PaymentComparisonEntity {
  final PeriodStatsEntity currentPeriod;
  final PeriodStatsEntity previousPeriod;
  final ChangeStatsEntity change;

  const PaymentComparisonEntity({
    required this.currentPeriod,
    required this.previousPeriod,
    required this.change,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentComparisonEntity &&
          other.currentPeriod == currentPeriod &&
          other.previousPeriod == previousPeriod &&
          other.change == change;

  @override
  int get hashCode => Object.hash(currentPeriod, previousPeriod, change);
}

/// Totales de un período. [startDate] y [endDate] son **días del negocio**
/// (medianoche local de ese día de calendario), no instantes.
class PeriodStatsEntity {
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final int paymentCount;
  final double averageAmount;

  const PeriodStatsEntity({
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.paymentCount,
    required this.averageAmount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeriodStatsEntity &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.totalAmount == totalAmount &&
          other.paymentCount == paymentCount &&
          other.averageAmount == averageAmount;

  @override
  int get hashCode =>
      Object.hash(startDate, endDate, totalAmount, paymentCount, averageAmount);
}

/// Diferencias (actual − anterior) y su porcentaje sobre el anterior, con 2
/// decimales. Sin base (el anterior es 0) el porcentaje es `null` (7.04-8):
/// la UI muestra "nuevo" (hubo algo) o "—".
class ChangeStatsEntity {
  final double amountDifference;
  final double? amountPercentage;
  final int countDifference;
  final double? countPercentage;
  final double averageDifference;
  final double? averagePercentage;

  const ChangeStatsEntity({
    required this.amountDifference,
    required this.amountPercentage,
    required this.countDifference,
    required this.countPercentage,
    required this.averageDifference,
    required this.averagePercentage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeStatsEntity &&
          other.amountDifference == amountDifference &&
          other.amountPercentage == amountPercentage &&
          other.countDifference == countDifference &&
          other.countPercentage == countPercentage &&
          other.averageDifference == averageDifference &&
          other.averagePercentage == averagePercentage;

  @override
  int get hashCode => Object.hash(amountDifference, amountPercentage,
      countDifference, countPercentage, averageDifference, averagePercentage);
}
