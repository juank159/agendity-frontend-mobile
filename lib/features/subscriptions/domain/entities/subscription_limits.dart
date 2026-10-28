/// Por qué el negocio no puede crear citas.
enum SubscriptionBlock {
  /// `TRIAL_LIMIT_REACHED`: se acabaron las citas de prueba.
  trialLimitReached,

  /// `SUBSCRIPTION_INACTIVE`: plan vencido, cancelado, sin pagar o sin cupo.
  inactive,
}

/// ¿Puede el negocio crear una cita ahora? (`GET /subscriptions/check-limits`).
/// Solo lectura: el backend vuelve a comprobarlo, de forma atómica, al crear
/// la cita.
class SubscriptionLimits {
  final bool canCreateAppointment;

  /// Texto del backend para el usuario ("Citas restantes en prueba: 5"…).
  final String message;

  /// `null` si [canCreateAppointment].
  final SubscriptionBlock? block;

  const SubscriptionLimits({
    required this.canCreateAppointment,
    this.message = '',
    this.block,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionLimits &&
          other.canCreateAppointment == canCreateAppointment &&
          other.message == message &&
          other.block == block;

  @override
  int get hashCode => Object.hash(canCreateAppointment, message, block);
}
