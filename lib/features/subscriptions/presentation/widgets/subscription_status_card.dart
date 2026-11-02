import 'package:flutter/material.dart';
import 'package:login_signup/core/config/color_contrast.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/shared/widgets/app_card.dart';

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
        AppCard(
          margin: EdgeInsets.zero,
          color: summary.tone.container,
          tint: summary.tone.color,
          child: Padding(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: tokens.gradientOf(summary.tone.color),
                        border: Border.all(color: tokens.innerBorder),
                      ),
                      child: Icon(summary.icon,
                          color: readableOn(summary.tone.color)),
                    ),
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
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: (subscription.trialAppointmentsUsed /
                              subscription.trialAppointmentsLimit)
                          .clamp(0.0, 1.0),
                      minHeight: 10,
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
          AppCard(
            margin: EdgeInsets.zero,
            depth: 1,
            color: tokens.warning.container,
            tint: tokens.warning.color,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: tokens.warning.color),
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
                      icon: const Icon(Icons.refresh_rounded),
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
          icon: ended ? Icons.info_rounded : Icons.card_giftcard_rounded,
          title: ended ? 'Tu periodo de prueba terminó' : 'Periodo de prueba',
          message: 'Usaste $used de $limit citas de prueba.'
              '${ended ? ' Elige un plan para seguir agendando.' : ''}',
        );
      case SubscriptionStatus.active:
        if (subscription.cancelAtPeriodEnd) {
          return _Summary(
            tone: tokens.warning,
            icon: Icons.event_busy_rounded,
            title: '$planName cancelado',
            message: end == null
                ? 'Sigue activo hasta el fin del periodo y no se renovará.'
                : 'Activo hasta el ${formatDate(end)}; no se renovará.',
          );
        }
        return _Summary(
          tone: tokens.success,
          icon: Icons.verified_rounded,
          title: '$planName activo',
          message: end == null
              ? 'Plan vigente.'
              : 'Vigente hasta el ${formatDate(end)}.',
        );
      case SubscriptionStatus.expired:
        return _Summary(
          tone: tokens.error,
          icon: Icons.event_busy_rounded,
          title: 'Tu plan venció',
          message: 'Elige un plan para seguir agendando citas.',
        );
      case SubscriptionStatus.canceled:
        return _Summary(
          tone: tokens.error,
          icon: Icons.cancel_rounded,
          title: 'Plan cancelado',
          message: 'Elige un plan para seguir agendando citas.',
        );
      case SubscriptionStatus.pastDue:
        return _Summary(
          tone: tokens.error,
          icon: Icons.warning_amber_rounded,
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
