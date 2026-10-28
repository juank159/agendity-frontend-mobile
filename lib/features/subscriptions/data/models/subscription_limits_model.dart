import 'package:login_signup/core/errors/error_codes.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_limits.dart';

/// DTO de `GET /subscriptions/check-limits` (`AppointmentAllowance`):
/// `{canCreateAppointment, message, code?}` (camelCase). El motivo del
/// bloqueo sale de `code`, nunca del texto.
class SubscriptionLimitsModel {
  final bool canCreateAppointment;
  final String message;
  final String? code;

  const SubscriptionLimitsModel({
    required this.canCreateAppointment,
    required this.message,
    this.code,
  });

  /// Sin `canCreateAppointment` no se deja agendar (como el backend ante un
  /// error al comprobarlo).
  factory SubscriptionLimitsModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionLimitsModel(
        canCreateAppointment:
            JsonRead.asBool(json['canCreateAppointment'], fallback: false),
        message: JsonRead.asString(json['message']),
        code: JsonRead.asOptionalString(json['code']),
      );

  SubscriptionLimits toEntity() => SubscriptionLimits(
        canCreateAppointment: canCreateAppointment,
        message: message,
        block: canCreateAppointment
            ? null
            : code == ApiErrorCode.trialLimitReached
                ? SubscriptionBlock.trialLimitReached
                : SubscriptionBlock.inactive,
      );
}
