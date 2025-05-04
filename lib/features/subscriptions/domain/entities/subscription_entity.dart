// lib/features/subscriptions/domain/entities/subscription_entity.dart

class SubscriptionEntity {
  final String id;
  final String tenantId;
  final String status; // 'trial', 'active', 'canceled', 'expired', etc.
  final int trialAppointmentsUsed;
  final int trialAppointmentsLimit;
  final bool isTrialUsed;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final SubscriptionPlanEntity? plan;

  SubscriptionEntity({
    required this.id,
    required this.tenantId,
    required this.status,
    required this.trialAppointmentsUsed,
    required this.trialAppointmentsLimit,
    required this.isTrialUsed,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.plan,
  });

  // Método para verificar si puede crear citas
  bool get canCreateAppointment {
    if (status == 'active' && plan != null) {
      return true;
    }

    if (status == 'trial' && trialAppointmentsUsed < trialAppointmentsLimit) {
      return true;
    }

    return false;
  }

  // Método para obtener el mensaje de estado
  String get statusMessage {
    if (status == 'trial') {
      final remaining = trialAppointmentsLimit - trialAppointmentsUsed;
      return 'Citas restantes en prueba: $remaining';
    }

    if (status == 'active' && plan != null) {
      return 'Plan ${plan!.name} activo hasta ${_formatDate(subscriptionEndDate)}';
    }

    if (status == 'expired') {
      return 'Tu suscripción ha expirado. Por favor, renueva tu plan.';
    }

    if (isTrialUsed) {
      return 'Has alcanzado el límite de citas de prueba. Por favor, adquiere un plan.';
    }

    return 'Suscripción inactiva';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class SubscriptionPlanEntity {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String billingInterval; // 'month' o 'year'
  final int appointmentLimit;
  final String wompiPriceId;
  final bool isActive;
  final List<String>? features;

  SubscriptionPlanEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.billingInterval,
    required this.appointmentLimit,
    required this.wompiPriceId,
    required this.isActive,
    this.features,
  });

  // Método para obtener la URL de pago de Wompi
  String get paymentUrl => 'https://checkout.wompi.co/l/$wompiPriceId';

  // Método para obtener la duración en meses
  int get durationMonths {
    if (name.toLowerCase().contains('semestral')) {
      return 6;
    } else if (name.toLowerCase().contains('anual') ||
        billingInterval == 'year') {
      return 12;
    }
    return 1; // Por defecto mensual
  }
}
