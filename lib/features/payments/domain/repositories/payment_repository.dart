import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/payments/domain/entities/custom_payment_method.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';

abstract class PaymentRepository {
  /// Registra el pago de una cita (solo Owner: el Employee recibe
  /// `ForbiddenFailure`). Admite anticipos hasta el total. Cita cancelada →
  /// `AppointmentNotPayableFailure`; ya pagada del todo → `ConflictFailure`
  /// (`PAYMENT_ALREADY_EXISTS`); monto mayor que el saldo → `ValidationFailure`
  /// (`BAD_REQUEST`) con el texto del backend.
  Future<Either<Failure, PaymentEntity>> createPayment(PaymentEntity payment);

  /// Pagos de una cita (`GET /payments/appointment/:id`, solo Owner), de
  /// cualquier estado.
  Future<Either<Failure, List<PaymentEntity>>> getAppointmentPayments(
      String appointmentId);

  /// Métodos propios activos del negocio (`GET /custom-payment-methods/active`),
  /// ordenados por nombre. Solo Owner: el Employee recibe `ForbiddenFailure`.
  Future<Either<Failure, List<CustomPaymentMethod>>>
      getActiveCustomPaymentMethods();
}
