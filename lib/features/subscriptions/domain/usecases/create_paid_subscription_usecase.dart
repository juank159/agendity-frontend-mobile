import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_checkout.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';

/// Inicia el pago de un plan (solo Owner): devuelve el enlace de pago. El plan
/// no queda activo hasta que se confirme el pago
/// (`RefreshSubscriptionStatusUseCase`).
class CreatePaidSubscriptionUseCase
    extends UseCase<SubscriptionCheckout, String> {
  static const missingPlanMessage = 'Selecciona un plan';

  final SubscriptionRepository repository;

  CreatePaidSubscriptionUseCase(this.repository);

  @override
  Future<Either<Failure, SubscriptionCheckout>> call(String planId) async {
    if (planId.trim().isEmpty) {
      return const Left(ValidationFailure(message: missingPlanMessage));
    }
    return repository.subscribe(planId.trim());
  }
}
