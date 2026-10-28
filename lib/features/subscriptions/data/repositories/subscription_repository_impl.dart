import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_checkout.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_limits.dart';
import 'package:login_signup/features/subscriptions/domain/failures/subscription_failures.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource _remote;

  SubscriptionRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<SubscriptionPlanEntity>>> getPlans() => safeCall(
      () async => (await _remote.getPlans()).map((m) => m.toEntity()).toList());

  @override
  Future<Either<Failure, SubscriptionEntity>> getStatus() =>
      safeCall(() async => (await _remote.getStatus()).toEntity(),
          refine: refineSubscriptionFailure);

  @override
  Future<Either<Failure, SubscriptionLimits>> checkLimits() =>
      safeCall(() async => (await _remote.checkLimits()).toEntity(),
          refine: refineSubscriptionFailure);

  @override
  Future<Either<Failure, SubscriptionCheckout>> subscribe(String planId) async {
    final result = await safeCall(
        () async => (await _remote.subscribe(planId)).toEntity(),
        refine: refineSubscriptionFailure);
    return result.flatMap((checkout) => checkout.paymentLink.isEmpty
        ? const Left(PaymentLinkUnavailableFailure())
        : Right(checkout));
  }

  @override
  Future<Either<Failure, SubscriptionRefresh>> refreshStatus() =>
      safeCall(() async => (await _remote.refreshStatus()).toEntity(),
          refine: refineSubscriptionFailure);
}
