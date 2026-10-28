import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_checkout.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_limits.dart';

/// Suscripción del negocio. El tenant lo saca el backend del JWT. Lecturas
/// (planes, estado, límites): Owner y Employee. Escrituras (`subscribe`,
/// `refresh-status`): solo Owner (`ForbiddenFailure`).
abstract class SubscriptionRepository {
  /// Planes activos.
  Future<Either<Failure, List<SubscriptionPlanEntity>>> getPlans();

  /// Estado efectivo, con `pending_payment` y `cancel_at_period_end`.
  Future<Either<Failure, SubscriptionEntity>> getStatus();

  /// ¿Se pueden crear citas ahora?
  Future<Either<Failure, SubscriptionLimits>> checkLimits();

  /// Crea un intento de pago del plan y devuelve el enlace.
  /// Sin enlace → `PaymentLinkUnavailableFailure`.
  Future<Either<Failure, SubscriptionCheckout>> subscribe(String planId);

  /// Pide al backend que consulte en Wompi el intento pendiente y lo aplique.
  Future<Either<Failure, SubscriptionRefresh>> refreshStatus();
}
