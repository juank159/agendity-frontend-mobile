/// Resultado de `POST /subscriptions/subscribe`: un intento de pago `pending`
/// y el enlace donde pagarlo. **No** cambia la suscripción: el negocio sigue
/// en su estado hasta que se confirma el pago (`refresh-status` o webhook).
class SubscriptionCheckout {
  /// Enlace de pago de Wompi (o `myapp://payment-demo…` en desarrollo).
  final String paymentLink;

  /// Id del intento (`payment_history`); `null` en el enlace de respaldo de
  /// desarrollo.
  final String? paymentAttemptId;

  /// Enlace de demostración (solo con `NODE_ENV=development`).
  final bool isTest;

  const SubscriptionCheckout({
    required this.paymentLink,
    this.paymentAttemptId,
    this.isTest = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionCheckout &&
          other.paymentLink == paymentLink &&
          other.paymentAttemptId == paymentAttemptId &&
          other.isTest == isTest;

  @override
  int get hashCode => Object.hash(paymentLink, paymentAttemptId, isTest);
}

/// Resultado de `POST /subscriptions/refresh-status`.
class SubscriptionRefresh {
  /// `true` solo si esta llamada activó el plan. `false` = sin cambios (no hay
  /// intento pendiente, Wompi aún no lo aprueba o fue rechazado).
  final bool activated;
  final String message;

  const SubscriptionRefresh({required this.activated, this.message = ''});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionRefresh &&
          other.activated == activated &&
          other.message == message;

  @override
  int get hashCode => Object.hash(activated, message);
}
