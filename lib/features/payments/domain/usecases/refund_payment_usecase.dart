import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';

class RefundPaymentParams {
  final PaymentEntity payment;
  final double amount;
  final String reason;

  const RefundPaymentParams(
      {required this.payment, required this.amount, required this.reason});
}

/// Reembolso de un pago (solo Owner; `POST /payments/:id/refund` o, sin
/// conexión, `payment.refund`). Monto > 0 y no mayor que lo que queda sin
/// devolver; motivo obligatorio (como el DTO).
class RefundPaymentUseCase extends UseCase<PaymentEntity, RefundPaymentParams> {
  static const invalidAmount =
      'El reembolso debe ser mayor que 0 y no superar lo que queda del pago';
  static const reasonRequired = 'Escribe el motivo del reembolso';

  final PaymentRepository repository;

  RefundPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentEntity>> call(RefundPaymentParams params) async {
    final id = params.payment.id;
    if (id == null) return const Left(NotFoundFailure());
    final cents = (params.amount * 100).round();
    final available = (params.payment.netAmount * 100).round();
    if (cents <= 0 || cents > available) {
      return const Left(ValidationFailure(message: invalidAmount));
    }
    final reason = params.reason.trim();
    if (reason.isEmpty || reason.length > 500) {
      return const Left(ValidationFailure(message: reasonRequired));
    }
    return repository.refundPayment(id, amount: cents / 100, reason: reason);
  }
}
