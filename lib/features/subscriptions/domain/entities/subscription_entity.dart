import 'package:login_signup/features/subscriptions/domain/entities/pending_payment.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_status.dart';

export 'package:login_signup/features/subscriptions/domain/entities/pending_payment.dart';
export 'package:login_signup/features/subscriptions/domain/entities/subscription_plan.dart';
export 'package:login_signup/features/subscriptions/domain/entities/subscription_status.dart';

/// Suscripción del negocio con su **estado efectivo** (`GET /subscriptions/status`):
/// el backend ya calcula `expired` (fecha de fin pasada) y deja `active` una
/// cancelada que sigue vigente ([cancelAtPeriodEnd]). Si y cuántas citas se
/// pueden crear lo dice `SubscriptionLimits` (`check-limits`), que cuenta las
/// citas del periodo de los planes con límite.
class SubscriptionEntity {
  /// `null` si el negocio aún no tiene fila (trial sin usar).
  final String? id;
  final SubscriptionStatus status;
  final int trialAppointmentsUsed;
  final int trialAppointmentsLimit;
  final bool isTrialUsed;
  final DateTime? startDate;
  final DateTime? endDate;
  final SubscriptionPlanEntity? plan;

  /// Cancelada, pero vigente (y sin renovación) hasta [endDate].
  final bool cancelAtPeriodEnd;
  final PendingPayment? pendingPayment;

  const SubscriptionEntity({
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

  bool get isTrial => status == SubscriptionStatus.trial;

  /// Plan pagado vigente (incluida una cancelación que aún no llega a su fin).
  bool get isActive => status == SubscriptionStatus.active && plan != null;

  int get trialAppointmentsRemaining {
    final remaining = trialAppointmentsLimit - trialAppointmentsUsed;
    return remaining < 0 ? 0 : remaining;
  }

  bool get hasPendingPayment => pendingPayment != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionEntity &&
          other.id == id &&
          other.status == status &&
          other.trialAppointmentsUsed == trialAppointmentsUsed &&
          other.trialAppointmentsLimit == trialAppointmentsLimit &&
          other.isTrialUsed == isTrialUsed &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.plan == plan &&
          other.cancelAtPeriodEnd == cancelAtPeriodEnd &&
          other.pendingPayment == pendingPayment;

  @override
  int get hashCode => Object.hash(
      id,
      status,
      trialAppointmentsUsed,
      trialAppointmentsLimit,
      isTrialUsed,
      startDate,
      endDate,
      plan,
      cancelAtPeriodEnd,
      pendingPayment);
}
