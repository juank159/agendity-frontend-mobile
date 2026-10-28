/// Estadísticas de un profesional (`GET /payments/employee-stats`): el
/// Employee ve las suyas; el Owner, las del profesional que pida.
class EmployeeStatsEntity {
  final EmployeeStatsSummary summary;

  /// Ordenado por [EmployeeServiceStats.total], de mayor a menor.
  final List<EmployeeServiceStats> byService;

  /// Un elemento por día con pagos, en orden ascendente.
  final List<EmployeeDailyStats> dailyEvolution;

  const EmployeeStatsEntity({
    this.summary = EmployeeStatsSummary.empty,
    this.byService = const [],
    this.dailyEvolution = const [],
  });

  bool get isEmpty => summary.paymentCount == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeStatsEntity &&
          other.summary == summary &&
          _listEquals(other.byService, byService) &&
          _listEquals(other.dailyEvolution, dailyEvolution);

  @override
  int get hashCode => Object.hash(
      summary, Object.hashAll(byService), Object.hashAll(dailyEvolution));
}

/// Totales netos del profesional en el rango.
class EmployeeStatsSummary {
  final double totalAmount;
  final int paymentCount;
  final int appointmentCount;
  final double averagePerPayment;

  const EmployeeStatsSummary({
    required this.totalAmount,
    required this.paymentCount,
    required this.appointmentCount,
    required this.averagePerPayment,
  });

  static const empty = EmployeeStatsSummary(
      totalAmount: 0,
      paymentCount: 0,
      appointmentCount: 0,
      averagePerPayment: 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeStatsSummary &&
          other.totalAmount == totalAmount &&
          other.paymentCount == paymentCount &&
          other.appointmentCount == appointmentCount &&
          other.averagePerPayment == averagePerPayment;

  @override
  int get hashCode => Object.hash(
      totalAmount, paymentCount, appointmentCount, averagePerPayment);
}

/// Servicios que hizo el profesional en citas pagadas. Igual que en
/// `stats/by-service`, [total] es precio de lista × veces (no lo cobrado).
class EmployeeServiceStats {
  final String serviceId;
  final String serviceName;
  final int count;
  final double total;

  const EmployeeServiceStats({
    required this.serviceId,
    required this.serviceName,
    required this.count,
    required this.total,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeServiceStats &&
          other.serviceId == serviceId &&
          other.serviceName == serviceName &&
          other.count == count &&
          other.total == total;

  @override
  int get hashCode => Object.hash(serviceId, serviceName, count, total);
}

/// Ingresos netos de un día del negocio.
class EmployeeDailyStats {
  /// Día del negocio (medianoche local de ese día de calendario).
  final DateTime day;
  final double total;

  /// Pagos de ese día.
  final int count;

  const EmployeeDailyStats({
    required this.day,
    required this.total,
    required this.count,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeDailyStats &&
          other.day == day &&
          other.total == total &&
          other.count == count;

  @override
  int get hashCode => Object.hash(day, total, count);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
