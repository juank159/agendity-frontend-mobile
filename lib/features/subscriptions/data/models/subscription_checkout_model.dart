import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_checkout.dart';

/// DTO de `POST /subscriptions/subscribe`: la suscripción (sin cambios) +
/// `payment_link`, `payment_attempt_id` y, en desarrollo, `is_test`.
class SubscriptionCheckoutModel {
  final String paymentLink;
  final String? paymentAttemptId;
  final bool isTest;

  const SubscriptionCheckoutModel({
    required this.paymentLink,
    this.paymentAttemptId,
    this.isTest = false,
  });

  factory SubscriptionCheckoutModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionCheckoutModel(
        paymentLink: JsonRead.asString(json['payment_link']),
        paymentAttemptId: JsonRead.asOptionalString(json['payment_attempt_id']),
        isTest: JsonRead.asBool(json['is_test'], fallback: false),
      );

  SubscriptionCheckout toEntity() => SubscriptionCheckout(
        paymentLink: paymentLink,
        paymentAttemptId: paymentAttemptId,
        isTest: isTest,
      );
}

/// DTO de `POST /subscriptions/refresh-status`: `{success, message}`.
class SubscriptionRefreshModel {
  final bool success;
  final String message;

  const SubscriptionRefreshModel({required this.success, this.message = ''});

  factory SubscriptionRefreshModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionRefreshModel(
        success: JsonRead.asBool(json['success'], fallback: false),
        message: JsonRead.asString(json['message']),
      );

  SubscriptionRefresh toEntity() =>
      SubscriptionRefresh(activated: success, message: message);
}
