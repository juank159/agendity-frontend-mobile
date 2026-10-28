import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/subscriptions/data/models/subscription_checkout_model.dart';
import 'package:login_signup/features/subscriptions/data/models/subscription_limits_model.dart';
import 'package:login_signup/features/subscriptions/data/models/subscription_model.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_checkout.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_limits.dart';

// Respuestas tal como las arma hoy `subscriptions.service.ts` (2.03, 2.05, 2.15):
// `price` decimal como texto, fechas con el offset del negocio y el estado
// efectivo calculado en la lectura.

/// Plan de `GET /subscriptions/plans` (fila de `subscription_plans`).
Map<String, dynamic> backendPlan({
  String id = 'plan-1',
  String name = 'Plan Mensual',
  Object? price = '29900.00',
  Object? durationMonths = 1,
  Object? appointmentLimit = -1,
  Object? features = const ['Citas ilimitadas', 'Recordatorios'],
}) =>
    {
      'id': id,
      'name': name,
      'description': 'Para negocios pequeños',
      'price': price,
      'currency': 'COP',
      'billing_interval': 'month',
      'duration_months': durationMonths,
      'is_recurring': false,
      'appointment_limit': appointmentLimit,
      'wompi_price_id': null,
      'is_active': true,
      'features': features,
      'created_at': '2026-10-01T08:00:00.000-05:00',
      'updated_at': '2026-10-01T08:00:00.000-05:00',
    };

/// `GET /subscriptions/status` de un negocio sin fila (trial sin usar).
Map<String, dynamic> backendTrialWithoutRow() => {
      'id': null,
      'tenant_id': 'owner-1',
      'status': 'trial',
      'wompi_customer_id': null,
      'wompi_subscription_id': null,
      'plan': null,
      'trial_appointments_used': 0,
      'trial_appointments_limit': 20,
      'subscription_start_date': null,
      'subscription_end_date': null,
      'is_trial_used': false,
      'payments': [],
      'created_at': null,
      'updated_at': null,
      'cancel_at_period_end': false,
      'pending_payment': null,
    };

/// `GET /subscriptions/status` en trial con un pago de plan sin confirmar.
Map<String, dynamic> backendTrialWithPendingPayment() => {
      ...backendTrialWithoutRow(),
      'id': 'sub-1',
      'trial_appointments_used': 7,
      'payments': [
        {'id': 'pay-1', 'status': 'pending', 'amount': '29900.00'}
      ],
      'pending_payment': {
        'id': 'pay-1',
        'plan_id': 'plan-1',
        'amount': 29900,
        'currency': 'COP',
        'created_at': '2026-10-26T10:15:00.000-05:00',
      },
    };

/// `GET /subscriptions/status` de un plan pagado vigente (o cancelado pero
/// vigente, con [cancelAtPeriodEnd]).
Map<String, dynamic> backendActive({bool cancelAtPeriodEnd = false}) => {
      ...backendTrialWithoutRow(),
      'id': 'sub-1',
      'status': 'active',
      'plan': backendPlan(),
      'trial_appointments_used': 20,
      'is_trial_used': true,
      'subscription_start_date': '2026-10-01T08:00:00.000-05:00',
      'subscription_end_date': '2026-11-01T08:00:00.000-05:00',
      'cancel_at_period_end': cancelAtPeriodEnd,
    };

/// `GET /subscriptions/check-limits`.
Map<String, dynamic> backendLimits(
        {bool can = true,
        String message = 'Citas restantes en prueba: 13',
        String? code}) =>
    {
      'canCreateAppointment': can,
      'message': message,
      if (code != null) 'code': code,
    };

/// `POST /subscriptions/subscribe` (201): la fila sin cambios + el enlace.
Map<String, dynamic> backendCheckout(
        {Object? link = 'https://checkout.wompi.co/l/abc123'}) =>
    {
      ...backendTrialWithoutRow(),
      'id': 'sub-1',
      'payment_attempt_id': 'pay-1',
      'payment_link': link,
    };

void main() {
  group('SubscriptionPlanModel', () {
    test('fromJson: precio en texto, duración, ilimitado y características',
        () {
      final plan = SubscriptionPlanModel.fromJson(backendPlan()).toEntity();
      expect(plan.id, 'plan-1');
      expect(plan.price, 29900.0);
      expect(plan.durationMonths, 1);
      expect(plan.hasUnlimitedAppointments, true);
      expect(plan.features, ['Citas ilimitadas', 'Recordatorios']);
      expect(plan.isActive, true);
    });

    test('semestral con límite; features null → lista vacía', () {
      final plan = SubscriptionPlanModel.fromJson(backendPlan(
              name: 'Plan Semestral',
              durationMonths: '6',
              appointmentLimit: 300,
              features: null))
          .toEntity();
      expect(plan.durationMonths, 6);
      expect(plan.appointmentLimit, 300);
      expect(plan.hasUnlimitedAppointments, false);
      expect(plan.features, isEmpty);
    });

    test('duración inválida → 1 mes (como el backend)', () {
      expect(
          SubscriptionPlanModel.fromJson(backendPlan(durationMonths: 0))
              .toEntity()
              .durationMonths,
          1);
    });
  });

  group('SubscriptionModel (GET /status)', () {
    test('negocio sin fila → trial sin usar, id null', () {
      final s = SubscriptionModel.fromJson(backendTrialWithoutRow()).toEntity();
      expect(s.id, isNull);
      expect(s.status, SubscriptionStatus.trial);
      expect(s.isTrial, true);
      expect(s.trialAppointmentsRemaining, 20);
      expect(s.hasPendingPayment, false);
      expect(s.isActive, false);
    });

    test('trial con pago pendiente: sigue en trial', () {
      final s = SubscriptionModel.fromJson(backendTrialWithPendingPayment())
          .toEntity();
      expect(s.status, SubscriptionStatus.trial);
      expect(s.trialAppointmentsRemaining, 13);
      expect(
          s.pendingPayment,
          PendingPayment(
            id: 'pay-1',
            planId: 'plan-1',
            amount: 29900,
            currency: 'COP',
            createdAt:
                BusinessTimeZone.toWallClock(DateTime.utc(2026, 10, 26, 15, 15)),
          ));
    });

    test('plan activo con fechas y plan anidado', () {
      final s = SubscriptionModel.fromJson(backendActive()).toEntity();
      expect(s.isActive, true);
      expect(s.plan!.name, 'Plan Mensual');
      expect(BusinessTimeZone.toInstant(s.endDate!), DateTime.utc(2026, 11, 1, 13));
      expect(s.cancelAtPeriodEnd, false);
    });

    test('cancelado pero vigente: active + cancelAtPeriodEnd', () {
      final s =
          SubscriptionModel.fromJson(backendActive(cancelAtPeriodEnd: true))
              .toEntity();
      expect(s.status, SubscriptionStatus.active);
      expect(s.isActive, true);
      expect(s.cancelAtPeriodEnd, true);
    });

    test('expired, past_due y estado desconocido', () {
      SubscriptionStatus statusOf(Object? raw) =>
          SubscriptionModel.fromJson({...backendActive(), 'status': raw})
              .toEntity()
              .status;
      expect(statusOf('expired'), SubscriptionStatus.expired);
      expect(statusOf('past_due'), SubscriptionStatus.pastDue);
      expect(statusOf('canceled'), SubscriptionStatus.canceled);
      // Desconocido: no deja dar nada por pagado.
      expect(statusOf('paused'), SubscriptionStatus.expired);
      expect(statusOf(null), SubscriptionStatus.trial);
    });
  });

  group('SubscriptionLimitsModel (GET /check-limits)', () {
    test('puede crear: sin bloqueo', () {
      expect(
          SubscriptionLimitsModel.fromJson(backendLimits()).toEntity(),
          const SubscriptionLimits(
              canCreateAppointment: true,
              message: 'Citas restantes en prueba: 13'));
    });

    test('bloqueo por code, no por texto', () {
      final trial = SubscriptionLimitsModel.fromJson(backendLimits(
              can: false,
              message: 'Has alcanzado el límite de citas de prueba.',
              code: 'TRIAL_LIMIT_REACHED'))
          .toEntity();
      expect(trial.block, SubscriptionBlock.trialLimitReached);

      // El texto dice "límite de citas" pero es el cupo del plan pagado.
      final planLimit = SubscriptionLimitsModel.fromJson(backendLimits(
              can: false,
              message: 'Has alcanzado el límite de citas de tu plan actual.',
              code: 'SUBSCRIPTION_INACTIVE'))
          .toEntity();
      expect(planLimit.block, SubscriptionBlock.inactive);
    });

    test('error al comprobar (sin code) → bloqueado como inactiva', () {
      final limits = SubscriptionLimitsModel.fromJson(backendLimits(
              can: false, message: 'Error al verificar estado de suscripción.'))
          .toEntity();
      expect(limits.canCreateAppointment, false);
      expect(limits.block, SubscriptionBlock.inactive);
      expect(SubscriptionLimitsModel.fromJson(const {}).toEntity().block,
          SubscriptionBlock.inactive);
    });
  });

  group('Subscribe y refresh-status', () {
    test('checkout: enlace e intento; is_test en desarrollo', () {
      expect(
          SubscriptionCheckoutModel.fromJson(backendCheckout()).toEntity(),
          const SubscriptionCheckout(
              paymentLink: 'https://checkout.wompi.co/l/abc123',
              paymentAttemptId: 'pay-1'));
      final demo = SubscriptionCheckoutModel.fromJson({
        ...backendCheckout(
            link: 'myapp://payment-demo?reference=sub_1&redirect=x'),
        'is_test': true,
      }).toEntity();
      expect(demo.isTest, true);
    });

    test('refresh: success → activated', () {
      expect(
          SubscriptionRefreshModel.fromJson({
            'success': true,
            'message': 'Suscripción verificada y activada correctamente'
          }).toEntity(),
          const SubscriptionRefresh(
              activated: true,
              message: 'Suscripción verificada y activada correctamente'));
      expect(
          SubscriptionRefreshModel.fromJson({
            'success': false,
            'message': 'No se encontraron cambios en la suscripción'
          }).toEntity().activated,
          false);
    });
  });
}
