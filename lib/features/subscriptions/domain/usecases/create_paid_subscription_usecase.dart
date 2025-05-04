// lib/features/subscriptions/domain/usecases/create_paid_subscription_usecase.dart

import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';

class CreatePaidSubscriptionUseCase {
  final SubscriptionRepository repository;

  CreatePaidSubscriptionUseCase(this.repository);

  Future<Map<String, dynamic>> call(String planId, String redirectUrl) async {
    return await repository.createPaidSubscription(planId, redirectUrl);
  }
}
