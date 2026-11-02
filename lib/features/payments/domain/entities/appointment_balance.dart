import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';

/// Lo pagado y lo que falta de una cita, con los pagos registrados
/// (anticipos, 2.24). Misma cuenta que el backend (`payment-rules.ts`): solo
/// cuentan los pagos `COMPLETED`, netos de reembolsos, en centavos.
class AppointmentBalance {
  final double total;

  /// Pagado neto (pagos `COMPLETED`: monto − reembolsado).
  final double paid;

  /// Pagos de la cita tal como llegaron (historial del detalle, 12.07),
  /// del más antiguo al más reciente; incluye los reembolsados y los que
  /// están en revisión (que no cuentan en [paid]). No entra en `==`: el
  /// saldo es [total] y [paid].
  final List<PaymentEntity> payments;

  const AppointmentBalance({
    required this.total,
    required this.paid,
    this.payments = const [],
  });

  /// Parte pagada del total, de 0 a 1 (barra de progreso).
  double get paidFraction {
    final totalCents = (total * 100).round();
    if (totalCents <= 0) return 0;
    return ((paid * 100).round() / totalCents).clamp(0.0, 1.0);
  }

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
