import 'package:login_signup/core/utils/deep_equality.dart';

/// Plan de suscripción que el negocio puede comprar (`GET /subscriptions/plans`
/// devuelve solo los activos). El pago se hace por un enlace que genera el
/// backend al suscribirse, no a partir del plan.
class SubscriptionPlanEntity {
  /// `appointment_limit` del backend para "citas ilimitadas".
  static const unlimitedAppointments = -1;

  final String id;
  final String name;
  final String description;

  /// Precio del periodo completo, en [currency] (COP).
  final double price;
  final String currency;

  /// Meses que dura el periodo pagado (1, 6, 12…). Lo usa el backend para
  /// calcular el fin; ya no se deduce del nombre.
  final int durationMonths;

  /// `'month'` o `'year'`: dato heredado; manda [durationMonths].
  final String billingInterval;
  final bool isRecurring;

  /// Citas por periodo; [unlimitedAppointments] = sin límite.
  final int appointmentLimit;
  final List<String> features;
  final bool isActive;

  const SubscriptionPlanEntity({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.currency = 'COP',
    this.durationMonths = 1,
    this.billingInterval = 'month',
    this.isRecurring = false,
    this.appointmentLimit = unlimitedAppointments,
    this.features = const [],
    this.isActive = true,
  });

  bool get hasUnlimitedAppointments => appointmentLimit < 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlanEntity &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.price == price &&
          other.currency == currency &&
          other.durationMonths == durationMonths &&
          other.billingInterval == billingInterval &&
          other.isRecurring == isRecurring &&
          other.appointmentLimit == appointmentLimit &&
          DeepEquality.lists(other.features, features) &&
          other.isActive == isActive;

  @override
  int get hashCode => Object.hash(
      id,
      name,
      description,
      price,
      currency,
      durationMonths,
      billingInterval,
      isRecurring,
      appointmentLimit,
      Object.hashAll(features),
      isActive);
}
