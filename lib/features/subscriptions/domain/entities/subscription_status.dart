/// Estado efectivo de la suscripción del negocio (`GET /subscriptions/status`),
/// igual que `SubscriptionStatus` del backend.
enum SubscriptionStatus {
  trial('trial'),
  active('active'),
  pastDue('past_due'),
  canceled('canceled'),
  expired('expired');

  final String apiValue;

  const SubscriptionStatus(this.apiValue);

  String toApi() => apiValue;

  /// Tolerante (mayúsculas, espacios, `cancelled`); `null` si no se reconoce.
  static SubscriptionStatus? fromApi(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase();
    if (normalized == 'cancelled') return canceled;
    for (final status in values) {
      if (status.apiValue == normalized) return status;
    }
    return null;
  }
}
