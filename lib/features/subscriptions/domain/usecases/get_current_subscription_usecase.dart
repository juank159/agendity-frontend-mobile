// lib/features/subscriptions/domain/usecases/get_current_subscription_usecase.dart

import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';

/// Obtiene la suscripción actual del negocio (`GET /subscriptions/status`).
/// Se usa para confirmar un pago: solo `status == 'active'` cuenta como pagado.
class GetCurrentSubscriptionUseCase {
  final SubscriptionRepository repository;

  GetCurrentSubscriptionUseCase(this.repository);

  Future<SubscriptionEntity> call() async {
    return await repository.getCurrentSubscription();
  }
}
