import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';

/// Suscripción del negocio con su estado efectivo (`GET /subscriptions/status`).
/// Un pago está confirmado solo si `isActive` (no basta la URL de la webview).
class GetCurrentSubscriptionUseCase
    extends UseCase<SubscriptionEntity, NoParams> {
  final SubscriptionRepository repository;

  GetCurrentSubscriptionUseCase(this.repository);

  @override
  Future<Either<Failure, SubscriptionEntity>> call(NoParams params) =>
      repository.getStatus();
}
