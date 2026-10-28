import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_checkout.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';

/// Verificación real del pago (solo Owner): el backend consulta en Wompi el
/// intento pendiente y lo aplica (misma regla que el webhook). Tras un
/// `Right`, el estado de verdad se lee con `GetCurrentSubscriptionUseCase`.
class RefreshSubscriptionStatusUseCase
    extends UseCase<SubscriptionRefresh, NoParams> {
  final SubscriptionRepository repository;

  RefreshSubscriptionStatusUseCase(this.repository);

  @override
  Future<Either<Failure, SubscriptionRefresh>> call(NoParams params) =>
      repository.refreshStatus();
}
