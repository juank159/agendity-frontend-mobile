// lib/features/subscriptions/domain/usecases/check_subscription_status_usecase.dart

import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';

class CheckSubscriptionStatusUseCase {
  final SubscriptionRepository repository;

  CheckSubscriptionStatusUseCase(this.repository);

  Future<Map<String, dynamic>> call() async {
    return await repository.checkSubscriptionStatus();
  }
}
