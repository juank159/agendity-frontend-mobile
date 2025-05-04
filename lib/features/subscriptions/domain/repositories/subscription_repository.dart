// lib/features/subscriptions/domain/repositories/subscription_repository.dart

import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';

abstract class SubscriptionRepository {
  // Obtener el estado de la suscripción
  Future<Map<String, dynamic>> checkSubscriptionStatus();

  // Obtener todos los planes disponibles
  Future<List<SubscriptionPlanEntity>> getAllPlans();

  // Obtener el plan por ID
  Future<SubscriptionPlanEntity> getPlanById(String id);

  // Obtener la suscripción actual
  Future<SubscriptionEntity> getCurrentSubscription();

  // Crear una suscripción pagada (usando un link de pago)
  Future<Map<String, dynamic>> createPaidSubscription(
      String planId, String redirectUrl);
}
