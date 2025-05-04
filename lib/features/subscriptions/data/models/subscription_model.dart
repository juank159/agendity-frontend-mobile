// lib/features/subscriptions/data/models/subscription_model.dart

import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';

class SubscriptionModel extends SubscriptionEntity {
  SubscriptionModel({
    required String id,
    required String tenantId,
    required String status,
    required int trialAppointmentsUsed,
    required int trialAppointmentsLimit,
    required bool isTrialUsed,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    SubscriptionPlanModel? plan,
  }) : super(
          id: id,
          tenantId: tenantId,
          status: status,
          trialAppointmentsUsed: trialAppointmentsUsed,
          trialAppointmentsLimit: trialAppointmentsLimit,
          isTrialUsed: isTrialUsed,
          subscriptionStartDate: subscriptionStartDate,
          subscriptionEndDate: subscriptionEndDate,
          plan: plan,
        );

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      status: json['status'] ?? 'trial',
      trialAppointmentsUsed: json['trial_appointments_used'] ?? 0,
      trialAppointmentsLimit: json['trial_appointments_limit'] ?? 20,
      isTrialUsed: json['is_trial_used'] ?? false,
      subscriptionStartDate: json['subscription_start_date'] != null
          ? DateTime.parse(json['subscription_start_date'])
          : null,
      subscriptionEndDate: json['subscription_end_date'] != null
          ? DateTime.parse(json['subscription_end_date'])
          : null,
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
      'subscription_start_date': subscriptionStartDate?.toIso8601String(),
      'subscription_end_date': subscriptionEndDate?.toIso8601String(),
      'plan': plan != null ? (plan as SubscriptionPlanModel).toJson() : null,
    };
  }
}

class SubscriptionPlanModel extends SubscriptionPlanEntity {
  SubscriptionPlanModel({
    required String id,
    required String name,
    required String description,
    required double price,
    required String currency,
    required String billingInterval,
    required int appointmentLimit,
    required String wompiPriceId,
    required bool isActive,
    List<String>? features,
  }) : super(
          id: id,
          name: name,
          description: description,
          price: price,
          currency: currency,
          billingInterval: billingInterval,
          appointmentLimit: appointmentLimit,
          wompiPriceId: wompiPriceId,
          isActive: isActive,
          features: features,
        );

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
