/// Intento de pago de un plan aún sin confirmar (`pending_payment` de
/// `GET /subscriptions/status`, 2.15). Mientras exista, la suscripción sigue
/// en su estado (p. ej. trial): solo Wompi (webhook o `refresh-status`) la
/// activa.
class PendingPayment {
  final String id;

  /// Plan que se está pagando; `null` en intentos antiguos sin ese dato.
  final String? planId;
  final double amount;
  final String currency;
  final DateTime? createdAt;

  const PendingPayment({
    required this.id,
    this.planId,
    required this.amount,
    this.currency = 'COP',
    this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingPayment &&
          other.id == id &&
          other.planId == planId &&
          other.amount == amount &&
          other.currency == currency &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, planId, amount, currency, createdAt);
}
