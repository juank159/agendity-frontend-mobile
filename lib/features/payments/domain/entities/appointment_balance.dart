/// Lo pagado y lo que falta de una cita, con los pagos registrados
/// (anticipos, 2.24). Misma cuenta que el backend (`payment-rules.ts`): solo
/// cuentan los pagos `COMPLETED`, netos de reembolsos, en centavos.
class AppointmentBalance {
  final double total;

  /// Pagado neto (pagos `COMPLETED`: monto − reembolsado).
  final double paid;

  const AppointmentBalance({required this.total, required this.paid});

  /// Lo que falta por pagar (nunca negativo). Es el máximo de un pago nuevo.
  double get outstanding {
    final cents = (total * 100).round() - (paid * 100).round();
    return cents <= 0 ? 0 : cents / 100;
  }

  bool get isFullyPaid => outstanding == 0;
  bool get hasPayments => (paid * 100).round() > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentBalance && other.total == total && other.paid == paid;

  @override
  int get hashCode => Object.hash(total, paid);

  @override
  String toString() => 'AppointmentBalance(total: $total, paid: $paid)';
}
