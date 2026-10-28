import 'package:login_signup/core/errors/failures.dart';

/// `TRIAL_LIMIT_REACHED`: se acabaron las citas de prueba. Lo devuelve el
/// backend al crear una cita (HTTP legado 400, D-11; se decide por `code`).
class TrialLimitReachedFailure extends PaymentRequiredFailure {
  static const defaultMessage =
      'Has alcanzado el límite de citas de prueba. Adquiere un plan para continuar.';

  const TrialLimitReachedFailure({
    String? message,
    super.statusCode,
    super.details,
  }) : super(
            message: message ?? defaultMessage,
            code: ApiErrorCode.trialLimitReached);
}

/// `SUBSCRIPTION_INACTIVE`: plan vencido, cancelado, sin pagar o sin cupo.
class SubscriptionInactiveFailure extends PaymentRequiredFailure {
  static const defaultMessage =
      'Tu suscripción no está activa. Por favor, actualiza tu plan.';

  const SubscriptionInactiveFailure({
    String? message,
    super.statusCode,
    super.details,
  }) : super(
            message: message ?? defaultMessage,
            code: ApiErrorCode.subscriptionInactive);
}

/// El backend respondió al `subscribe` sin enlace de pago.
class PaymentLinkUnavailableFailure extends ServerFailure {
  static const defaultMessage =
      'El servidor no devolvió un enlace de pago. Inténtalo de nuevo más tarde.';

  const PaymentLinkUnavailableFailure() : super(message: defaultMessage);
}

/// `refine` de `safeCall` para toda petición que pueda topar con el límite de
/// la suscripción (también la de crear cita, 4.09): por `code`, nunca por texto.
Failure refineSubscriptionFailure(Failure failure) => switch (failure.code) {
      ApiErrorCode.trialLimitReached => TrialLimitReachedFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          details: failure.details),
      ApiErrorCode.subscriptionInactive => SubscriptionInactiveFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          details: failure.details),
      _ => failure,
    };
