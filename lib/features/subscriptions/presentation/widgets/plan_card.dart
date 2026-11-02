import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/status_chip.dart';

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

/// Precio por mes de [plan] (`null` si no tiene duración válida).
double? planMonthlyPrice(SubscriptionPlanEntity plan) =>
    plan.durationMonths < 1 ? null : plan.price / plan.durationMonths;

/// Plan que se destaca en la pantalla: el de **menor precio por mes**, solo
/// si hay al menos dos planes en la misma moneda y uno sale más barato que
/// todos los demás (un empate no destaca a ninguno). Es un hecho que se
/// calcula con los datos del plan, no una recomendación inventada.
String? bestValuePlanId(List<SubscriptionPlanEntity> plans) {
  final priced = [
    for (final plan in plans)
      if (planMonthlyPrice(plan) case final monthly? when plan.price > 0)
        (plan: plan, monthly: monthly),
  ];
  if (priced.length < 2) return null;
  if (priced.map((p) => p.plan.currency).toSet().length > 1) return null;
  priced.sort((a, b) => a.monthly.compareTo(b.monthly));
  if (priced[0].monthly == priced[1].monthly) return null;
  return priced.first.plan.id;
}

/// Tarjeta de un plan con su precio por periodo y el botón para pagarlo. El
/// plan destacado ([highlighted]) lleva la cinta "Mejor precio por mes", el
/// borde del degradado de la paleta y más profundidad; el actual, la
/// píldora "Plan actual".
class PlanCard extends StatelessWidget {
  final SubscriptionPlanEntity plan;
  final bool isCurrent;
  final bool isStarting;
  final bool highlighted;

  /// `null` deshabilita el botón (p. ej. mientras se pide otro enlace).
  final VoidCallback? onSelect;

  const PlanCard({
    super.key,
    required this.plan,
    this.isCurrent = false,
    this.isStarting = false,
    this.highlighted = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final monthly = planMonthlyPrice(plan);
    final label = isCurrent ? 'Renovar plan' : 'Elegir plan';
    final card = AppCard(
      margin: EdgeInsets.zero,
      depth: highlighted ? 3 : 2,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: highlighted ? tokens.primaryGradient : null,
                  color: highlighted ? null : scheme.primaryContainer,
                  borderRadius: AppRadii.chipRadius,
                ),
                child: Icon(Icons.workspace_premium_rounded,
                    color: highlighted
                        ? tokens.onGradient
                        : scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  plan.name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (isCurrent)
                StatusChip(
                  label: 'Plan actual',
                  icon: Icons.check_circle_rounded,
                  colors: tokens.success,
                ),
            ],
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(plan.description,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatMoney(plan.price, currency: plan.currency),
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(
                          fontWeight: FontWeight.w800, color: scheme.primary)
                      .tabular,
                ),
                TextSpan(
                  text: ' / ${planPeriodLabel(plan.durationMonths)}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (monthly != null && plan.durationMonths > 1)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Equivale a ${formatMoney(monthly.roundToDouble(), currency: plan.currency)} al mes',
                style: theme.textTheme.bodySmall?.tabular
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          for (final feature in [
            planAppointmentsLabel(plan),
            ...plan.features
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: tokens.success.color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(feature, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          if (highlighted)
            AppGradientButton(
              label: label,
              icon: Icons.bolt_rounded,
              expand: true,
              loading: isStarting,
              onPressed: onSelect,
            )
          else
            FilledButton.tonal(
              onPressed: isStarting ? null : onSelect,
              child: isStarting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(label),
            ),
        ],
      ),
    );
    if (!highlighted) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: tokens.primaryGradient,
            borderRadius:
                const BorderRadius.all(Radius.circular(AppRadii.card + 2)),
          ),
          child: card,
        ),
        Positioned(
          top: -12,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: tokens.primaryGradient,
              borderRadius: AppRadii.chipRadius,
              border: Border.all(color: tokens.innerBorder),
              boxShadow: tokens.elevation2(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 16, color: tokens.onGradient),
                const SizedBox(width: 4),
                Text('Mejor precio por mes',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: tokens.onGradient,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
