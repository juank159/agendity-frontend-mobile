// lib/features/subscriptions/domain/usecases/get_all_plans_usecase.dart

import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';

class GetAllPlansUseCase {
  final SubscriptionRepository repository;

  GetAllPlansUseCase(this.repository);

  Future<List<SubscriptionPlanEntity>> call() async {
    return await repository.getAllPlans();
  }
}
