import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/core/widgets/state_illustration.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';
import '../widgets/plan_card.dart';

/// Pago confirmado. Recibe por `arguments` la [SubscriptionEntity] que el
/// backend devolvió activa al verificar el pago.
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final args = Get.arguments;
    final subscription = args is SubscriptionEntity ? args : null;
    final plan = subscription?.plan;
    final end = subscription?.endDate;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppFadeIn(
                    child: Center(
                      child: StateIllustration(
                        icon: Icons.verified_rounded,
                        tone: AppTone.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Semantics(
                    header: true,
                    child: Text(
                      '¡Gracias por tu compra!',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tu suscripción quedó activa.',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  if (plan != null) ...[
                    const SizedBox(height: 28),
                    AppFadeIn(
                      index: 1,
                      child: AppCard(
                        margin: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppSectionHeader(
                              icon: Icons.workspace_premium_rounded,
                              title: plan.name,
                              subtitle: 'Tu plan',
                              padding: const EdgeInsets.only(bottom: 10),
                            ),
                            _row(context, Icons.payments_rounded, 'Precio',
                                '${formatMoney(plan.price, currency: plan.currency)} / ${planPeriodLabel(plan.durationMonths)}'),
                            _row(context, Icons.event_available_rounded,
                                'Citas', planAppointmentsLabel(plan)),
                            if (end != null)
                              _row(context, Icons.event_rounded,
                                  'Vigente hasta', formatDate(end)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  AppGradientButton(
                    label: 'Comenzar a usar',
                    icon: Icons.arrow_forward_rounded,
                    expand: true,
                    onPressed: () => Get.offAllNamed(GetRoutes.home),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)
                    .tabular),
          ),
        ],
      ),
    );
  }
}
