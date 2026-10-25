import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/payments/domain/entities/custom_payment_method.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';

/// Métodos propios activos del negocio, por nombre. Solo Owner: el Employee
/// recibe `ForbiddenFailure`.
class GetActiveCustomPaymentMethodsUseCase
    extends UseCase<List<CustomPaymentMethod>, NoParams> {
  final PaymentRepository repository;

  GetActiveCustomPaymentMethodsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CustomPaymentMethod>>> call(NoParams params) =>
      repository.getActiveCustomPaymentMethods();
}
