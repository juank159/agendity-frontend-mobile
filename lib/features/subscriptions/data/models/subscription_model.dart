import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';

/// DTO de `GET /subscriptions/status` (`SubscriptionStatusView`): la fila de
/// `subscriptions` con el estado efectivo, el `plan` anidado (o `null`),
/// `cancel_at_period_end` y `pending_payment`. Sin fila: `id` null y trial sin
/// usar. Se ignoran `tenant_id`, `wompi_*` y `payments`.
class SubscriptionModel {
  final String? id;
  final SubscriptionStatus status;
  final int trialAppointmentsUsed;
  final int trialAppointmentsLimit;
  final bool isTrialUsed;
  final DateTime? startDate;
  final DateTime? endDate;
  final SubscriptionPlanModel? plan;
  final bool cancelAtPeriodEnd;
  final PendingPaymentModel? pendingPayment;

  const SubscriptionModel({
    this.id,
    required this.status,
    this.trialAppointmentsUsed = 0,
    this.trialAppointmentsLimit = 0,
    this.isTrialUsed = false,
    this.startDate,
    this.endDate,
    this.plan,
    this.cancelAtPeriodEnd = false,
    this.pendingPayment,
  });

  /// Un estado que la app no conoce se trata como `expired` (no deja agendar
  /// ni da por pagado nada); falta el estado → trial, como responde el
  /// backend sin fila.
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final plan = JsonRead.asMap(json['plan']);
    final pending = JsonRead.asMap(json['pending_payment']);
    final rawStatus = json['status'];
    return SubscriptionModel(
      id: JsonRead.asOptionalString(json['id']),
      status: rawStatus == null
          ? SubscriptionStatus.trial
          : SubscriptionStatus.fromApi(rawStatus) ?? SubscriptionStatus.expired,
      trialAppointmentsUsed: JsonRead.asInt(json['trial_appointments_used']),
      trialAppointmentsLimit: JsonRead.asInt(json['trial_appointments_limit']),
      isTrialUsed: JsonRead.asBool(json['is_trial_used'], fallback: false),
      startDate: DateCodec.tryDecode(json['subscription_start_date']),
      endDate: DateCodec.tryDecode(json['subscription_end_date']),
      plan: plan == null ? null : SubscriptionPlanModel.fromJson(plan),
      cancelAtPeriodEnd:
          JsonRead.asBool(json['cancel_at_period_end'], fallback: false),
      pendingPayment:
          pending == null ? null : PendingPaymentModel.fromJson(pending),
    );
  }

  SubscriptionEntity toEntity() => SubscriptionEntity(
        id: id,
        status: status,
        trialAppointmentsUsed: trialAppointmentsUsed,
        trialAppointmentsLimit: trialAppointmentsLimit,
        isTrialUsed: isTrialUsed,
        startDate: startDate,
        endDate: endDate,
        plan: plan?.toEntity(),
        cancelAtPeriodEnd: cancelAtPeriodEnd,
        pendingPayment: pendingPayment?.toEntity(),
      );
}

/// DTO de `subscription_plans` (`price` decimal → texto; `features`
/// simple-array → lista o `null`). Se ignoran `wompi_price_id` y las fechas.
class SubscriptionPlanModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int durationMonths;
  final String billingInterval;
  final bool isRecurring;
  final int appointmentLimit;
  final List<String> features;
  final bool isActive;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationMonths,
    required this.billingInterval,
    required this.isRecurring,
    required this.appointmentLimit,
    required this.features,
    required this.isActive,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    final months = JsonRead.asInt(json['duration_months'], fallback: 1);
    final rawFeatures = json['features'];
    return SubscriptionPlanModel(
      id: JsonRead.asString(json['id']),
      name: JsonRead.asString(json['name']),
      description: JsonRead.asString(json['description']),
      price: JsonRead.asDouble(json['price']),
      currency: JsonRead.asString(json['currency'], fallback: 'COP'),
      // Igual que el backend: una duración inválida cuenta como 1 mes.
      durationMonths: months >= 1 ? months : 1,
      billingInterval:
          JsonRead.asString(json['billing_interval'], fallback: 'month'),
      isRecurring: JsonRead.asBool(json['is_recurring'], fallback: false),
      appointmentLimit: JsonRead.asInt(json['appointment_limit'],
          fallback: SubscriptionPlanEntity.unlimitedAppointments),
      features: rawFeatures is List
          ? [
              for (final f in rawFeatures)
                if (JsonRead.asOptionalString(f) case final text?) text
            ]
          : const [],
      isActive: JsonRead.asBool(json['is_active'], fallback: true),
    );
  }

  SubscriptionPlanEntity toEntity() => SubscriptionPlanEntity(
        id: id,
        name: name,
        description: description,
        price: price,
        currency: currency,
        durationMonths: durationMonths,
        billingInterval: billingInterval,
        isRecurring: isRecurring,
        appointmentLimit: appointmentLimit,
        features: List.unmodifiable(features),
        isActive: isActive,
      );
}

/// DTO de `pending_payment` (`amount` ya convertido con `Number()`).
class PendingPaymentModel {
  final String id;
  final String? planId;
  final double amount;
  final String currency;
  final DateTime? createdAt;

  const PendingPaymentModel({
    required this.id,
    this.planId,
    required this.amount,
    required this.currency,
    this.createdAt,
  });

  factory PendingPaymentModel.fromJson(Map<String, dynamic> json) =>
      PendingPaymentModel(
        id: JsonRead.asString(json['id']),
        planId: JsonRead.asOptionalString(json['plan_id']),
        amount: JsonRead.asDouble(json['amount']),
        currency: JsonRead.asString(json['currency'], fallback: 'COP'),
        createdAt: DateCodec.tryDecode(json['created_at']),
      );

  PendingPayment toEntity() => PendingPayment(
        id: id,
        planId: planId,
        amount: amount,
        currency: currency,
        createdAt: createdAt,
      );
}
