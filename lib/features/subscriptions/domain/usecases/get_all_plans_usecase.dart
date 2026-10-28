import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';

/// Planes activos, del más corto al más largo (y por precio a igual duración).
class GetAllPlansUseCase
    extends UseCase<List<SubscriptionPlanEntity>, NoParams> {
  final SubscriptionRepository repository;

  GetAllPlansUseCase(this.repository);

  @override
  Future<Either<Failure, List<SubscriptionPlanEntity>>> call(
          NoParams params) async =>
      (await repository.getPlans()).map((plans) => [...plans]..sort((a, b) {
          final byDuration = a.durationMonths.compareTo(b.durationMonths);
          return byDuration != 0 ? byDuration : a.price.compareTo(b.price);
        }));
}
