import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/payments/domain/entities/payment_review_item.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';

/// "Pagos por revisar" (10.03, solo Owner): pagos registrados sin conexión
/// que al sincronizar no cabían (la cita estaba cancelada o se pagó de más).
/// El dinero ya se recibió; se resuelven con un reembolso.
class GetPaymentsInReviewUseCase
    extends UseCase<List<PaymentReviewItem>, NoParams> {
  final PaymentRepository repository;

  GetPaymentsInReviewUseCase(this.repository);

  @override
  Future<Either<Failure, List<PaymentReviewItem>>> call(NoParams params) =>
      repository.getPaymentsInReview();
}
