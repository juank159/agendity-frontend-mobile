import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_limits.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';

/// ¿Puede el negocio crear una cita ahora? (`GET /subscriptions/check-limits`).
/// Un bloqueo no es un `Left`: es `Right` con `canCreateAppointment == false`
/// y su [SubscriptionLimits.block].
class CheckSubscriptionLimitsUseCase
    extends UseCase<SubscriptionLimits, NoParams> {
  final SubscriptionRepository repository;

  CheckSubscriptionLimitsUseCase(this.repository);

  @override
  Future<Either<Failure, SubscriptionLimits>> call(NoParams params) =>
      repository.checkLimits();
}
