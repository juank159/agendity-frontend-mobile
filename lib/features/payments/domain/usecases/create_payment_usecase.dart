import 'package:dartz/dartz.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/payments/domain/failures/payment_failures.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';

class CreatePaymentParams {
  final String appointmentId;
  final double amount;
  final PaymentMethod method;

  /// Obligatorio si [method] es `CUSTOM`.
  final String? customPaymentMethodId;
  final String? transactionId;

  /// Total de la cita, para rechazar un monto mayor sin ir al backend.
  final double? appointmentTotal;

  const CreatePaymentParams({
    required this.appointmentId,
    required this.amount,
    required this.method,
    this.customPaymentMethodId,
    this.transactionId,
    this.appointmentTotal,
  });
}

/// Valida el pago con las mismas reglas del backend (monto y método) y lo
/// registra. Las reglas que dependen del servidor (cita cancelada o ya pagada)
/// llegan como failure del repositorio.
class CreatePaymentUseCase extends UseCase<PaymentEntity, CreatePaymentParams> {
  final PaymentRepository repository;

  CreatePaymentUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentEntity>> call(CreatePaymentParams params) async {
    final invalid = _validate(params);
    if (invalid != null) return Left(invalid);

    final transactionId = params.transactionId?.trim();
    final isCustom = params.method == PaymentMethod.CUSTOM;
    return repository.createPayment(PaymentEntity(
      appointmentId: params.appointmentId,
      amount: params.amount,
      paymentMethod: params.method,
      customPaymentMethodId: isCustom ? params.customPaymentMethodId : null,
      transactionId:
          transactionId == null || transactionId.isEmpty ? null : transactionId,
    ));
  }

  static Failure? _validate(CreatePaymentParams params) {
    final cents = params.amount * 100;
    if (!params.amount.isFinite || cents.round() <= 0) {
      return const InvalidPaymentAmountFailure(
          message: InvalidPaymentAmountFailure.notPositiveMessage);
    }
    if ((cents - cents.round()).abs() > 1e-6) {
      return const InvalidPaymentAmountFailure(
          message: InvalidPaymentAmountFailure.tooManyDecimalsMessage);
    }
    final total = params.appointmentTotal;
    if (total != null && cents.round() > (total * 100).round()) {
      return const InvalidPaymentAmountFailure(
          message: InvalidPaymentAmountFailure.exceedsTotalMessage);
    }
    final customId = params.customPaymentMethodId;
    if (params.method == PaymentMethod.CUSTOM &&
        (customId == null || customId.isEmpty)) {
      return const ValidationFailure(message: 'Elige el método de pago');
    }
    return null;
  }
}
