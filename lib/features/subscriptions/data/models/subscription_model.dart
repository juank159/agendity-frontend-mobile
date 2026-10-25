// lib/features/subscriptions/data/models/subscription_model.dart

import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/core/utils/date_codec.dart';

class SubscriptionModel extends SubscriptionEntity {
  SubscriptionModel({
    required super.id,
    required super.tenantId,
    required super.status,
    required super.trialAppointmentsUsed,
    required super.trialAppointmentsLimit,
    required super.isTrialUsed,
    super.subscriptionStartDate,
    super.subscriptionEndDate,
    SubscriptionPlanModel? super.plan,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      status: json['status'] ?? 'trial',
      trialAppointmentsUsed: json['trial_appointments_used'] ?? 0,
      trialAppointmentsLimit: json['trial_appointments_limit'] ?? 20,
      isTrialUsed: json['is_trial_used'] ?? false,
      subscriptionStartDate: DateCodec.tryDecode(json['subscription_start_date']),
      subscriptionEndDate: DateCodec.tryDecode(json['subscription_end_date']),
      plan: json['plan'] != null
          ? SubscriptionPlanModel.fromJson(json['plan'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'status': status,
      'trial_appointments_used': trialAppointmentsUsed,
      'trial_appointments_limit': trialAppointmentsLimit,
      'is_trial_used': isTrialUsed,
      'subscription_start_date': DateCodec.encodeOrNull(subscriptionStartDate),
      'subscription_end_date': DateCodec.encodeOrNull(subscriptionEndDate),
      'plan': plan != null ? (plan as SubscriptionPlanModel).toJson() : null,
    };
  }
}

class SubscriptionPlanModel extends SubscriptionPlanEntity {
  SubscriptionPlanModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.currency,
    required super.billingInterval,
    required super.appointmentLimit,
    required super.wompiPriceId,
    required super.isActive,
    super.features,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : double.parse(json['price'].toString()),
      currency: json['currency'] ?? 'COP',
      billingInterval: json['billing_interval'] ?? 'month',
      appointmentLimit: json['appointment_limit'] ?? -1,
      wompiPriceId: json['wompi_price_id'] ?? '',
      isActive: json['is_active'] ?? true,
      features:
          json['features'] != null ? List<String>.from(json['features']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'billing_interval': billingInterval,
      'appointment_limit': appointmentLimit,
      'wompi_price_id': wompiPriceId,
      'is_active': isActive,
      'features': features,
    };
  }
}
