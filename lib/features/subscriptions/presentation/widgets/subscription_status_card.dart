import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';

/// Estado de la suscripción del negocio: trial (citas usadas), plan activo,
/// cancelación al fin del periodo, vencida y pago en verificación.
class SubscriptionStatusCard extends StatelessWidget {
  final SubscriptionEntity subscription;
  final bool isVerifying;
  final VoidCallback onVerifyPending;

  const SubscriptionStatusCard({
    super.key,
    required this.subscription,
    required this.isVerifying,
    required this.onVerifyPending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final summary = _summary(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: summary.tone.container,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(summary.icon, color: summary.tone.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        summary.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: summary.tone.onContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  summary.message,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: summary.tone.onContainer),
                ),
                if (subscription.isTrial &&
                    subscription.trialAppointmentsLimit > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (subscription.trialAppointmentsUsed /
                              subscription.trialAppointmentsLimit)
                          .clamp(0.0, 1.0),
                      minHeight: 8,
                      color: summary.tone.color,
                      backgroundColor:
                          summary.tone.color.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (subscription.pendingPayment case final pending?) ...[
          const SizedBox(height: 8),
          Card(
            color: tokens.warning.container,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hourglass_top, color: tokens.warning.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pago en verificación',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: tokens.warning.onContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tienes un pago de '
                    '${formatMoney(pending.amount, currency: pending.currency)} '
                    'sin confirmar. Tu plan cambia cuando Wompi lo apruebe.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: tokens.warning.onContainer),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: isVerifying ? null : onVerifyPending,
                      icon: const Icon(Icons.refresh),
                      label:
                          Text(isVerifying ? 'Verificando…' : 'Verificar pago'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  _Summary _summary(BuildContext context) {
    final tokens = context.tokens;
    final end = subscription.endDate;
    final planName = subscription.plan?.name ?? 'Tu plan';
    switch (subscription.status) {
      case SubscriptionStatus.trial:
        final used = subscription.trialAppointmentsUsed;
        final limit = subscription.trialAppointmentsLimit;
        final ended = subscription.trialAppointmentsRemaining == 0;
        return _Summary(
          tone: ended ? tokens.warning : tokens.info,
          icon: ended ? Icons.info_outline : Icons.card_giftcard,
          title: ended ? 'Tu periodo de prueba terminó' : 'Periodo de prueba',
          message: 'Usaste $used de $limit citas de prueba.'
              '${ended ? ' Elige un plan para seguir agendando.' : ''}',
        );
      case SubscriptionStatus.active:
        if (subscription.cancelAtPeriodEnd) {
          return _Summary(
            tone: tokens.warning,
            icon: Icons.event_busy,
            title: '$planName cancelado',
            message: end == null
                ? 'Sigue activo hasta el fin del periodo y no se renovará.'
                : 'Activo hasta el ${formatDate(end)}; no se renovará.',
          );
        }
        return _Summary(
          tone: tokens.success,
          icon: Icons.verified_outlined,
          title: '$planName activo',
          message: end == null
              ? 'Plan vigente.'
              : 'Vigente hasta el ${formatDate(end)}.',
        );
      case SubscriptionStatus.expired:
        return _Summary(
          tone: tokens.error,
          icon: Icons.event_busy,
          title: 'Tu plan venció',
          message: 'Elige un plan para seguir agendando citas.',
        );
      case SubscriptionStatus.canceled:
        return _Summary(
          tone: tokens.error,
          icon: Icons.cancel_outlined,
          title: 'Plan cancelado',
          message: 'Elige un plan para seguir agendando citas.',
        );
      case SubscriptionStatus.pastDue:
        return _Summary(
          tone: tokens.error,
          icon: Icons.warning_amber,
          title: 'Pago vencido',
          message: 'Renueva tu plan para seguir agendando citas.',
        );
    }
  }
}

class _Summary {
  final ToneColors tone;
  final IconData icon;
  final String title;
  final String message;

  const _Summary({
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
  });
}
