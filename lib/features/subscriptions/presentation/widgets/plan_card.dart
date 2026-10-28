import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';

/// Duración del periodo pagado, según `duration_months` (nunca el nombre).
String planPeriodLabel(int months) {
  if (months <= 1) return 'mes';
  if (months % 12 == 0) return months == 12 ? 'año' : '${months ~/ 12} años';
  return '$months meses';
}

/// Cupo de citas del plan (`-1` = ilimitado).
String planAppointmentsLabel(SubscriptionPlanEntity plan) =>
    plan.hasUnlimitedAppointments
        ? 'Citas ilimitadas'
        : '${plan.appointmentLimit} citas por periodo';

/// Tarjeta de un plan con su precio por periodo y el botón para pagarlo.
class PlanCard extends StatelessWidget {
  final SubscriptionPlanEntity plan;
  final bool isCurrent;
  final bool isStarting;

  /// `null` deshabilita el botón (p. ej. mientras se pide otro enlace).
  final VoidCallback? onSelect;

  const PlanCard({
    super.key,
    required this.plan,
    this.isCurrent = false,
    this.isStarting = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isCurrent)
                  Chip(
                    label: const Text('Plan actual'),
                    backgroundColor: scheme.primaryContainer,
                    labelStyle: TextStyle(color: scheme.onPrimaryContainer),
                  ),
              ],
            ),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(plan.description, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatMoney(plan.price, currency: plan.currency),
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: scheme.primary),
                  ),
                  TextSpan(
                    text: ' / ${planPeriodLabel(plan.durationMonths)}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final feature in [
              planAppointmentsLabel(plan),
              ...plan.features
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: tokens.success.color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(feature, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onSelect,
              child: isStarting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isCurrent ? 'Renovar plan' : 'Elegir plan'),
            ),
          ],
        ),
      ),
    );
  }
}
