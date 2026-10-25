import 'package:login_signup/core/errors/failures.dart';

/// Monto fuera de la regla del backend (> 0, ≤ total de la cita, 2 decimales).
/// Lo detecta el use case antes de llamar al backend.
class InvalidPaymentAmountFailure extends ValidationFailure {
  static const notPositiveMessage = 'El monto del pago debe ser mayor que cero';
  static const exceedsTotalMessage =
      'El monto del pago no puede superar el total de la cita';
  static const tooManyDecimalsMessage =
      'El monto del pago admite como máximo 2 decimales';

  const InvalidPaymentAmountFailure({super.message});
}

/// La cita no admite pagos: está cancelada (`INVALID_STATE_TRANSITION`, 409).
class AppointmentNotPayableFailure extends ConflictFailure {
  static const defaultMessage =
      'No se puede registrar un pago en una cita cancelada';

  const AppointmentNotPayableFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}
