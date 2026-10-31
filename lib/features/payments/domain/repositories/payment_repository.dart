import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/payments/domain/entities/custom_payment_method.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/payments/domain/entities/payment_review_item.dart';

abstract class PaymentRepository {
  /// Pagos en revisión (`reviewRequired`), con su cita (10.03, solo Owner).
  Future<Either<Failure, List<PaymentReviewItem>>> getPaymentsInReview();

  /// Reembolsa [amount] del pago [paymentId] (se acumula). Sin conexión,
  /// en local + bandeja (`payment.refund`).
  Future<Either<Failure, PaymentEntity>> refundPayment(String paymentId,
      {required double amount, required String reason});

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
