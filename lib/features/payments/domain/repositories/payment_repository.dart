import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';

abstract class PaymentRepository {
  /// Registra el pago de una cita (solo Owner: el Employee recibe
  /// `ForbiddenFailure`). Cita cancelada → `AppointmentNotPayableFailure`;
  /// cita ya pagada o monto rechazado → `ValidationFailure` con el texto del
  /// backend (los dos llegan como `BAD_REQUEST`).
  Future<Either<Failure, PaymentEntity>> createPayment(PaymentEntity payment);
}
