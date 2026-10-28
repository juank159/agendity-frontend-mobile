import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import '../widgets/plan_card.dart';

/// Pago confirmado. Recibe por `arguments` la [SubscriptionEntity] que el
/// backend devolvió activa al verificar el pago.
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final args = Get.arguments;
    final subscription = args is SubscriptionEntity ? args : null;
    final plan = subscription?.plan;
    final end = subscription?.endDate;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: tokens.success.container,
                  child: Icon(Icons.check_circle,
                      color: tokens.success.color, size: 72),
                ),
                const SizedBox(height: 32),
                Text(
                  '¡Gracias por tu compra!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tokens.success.onContainer),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu suscripción quedó activa.',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                if (plan != null) ...[
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _row(context, 'Plan', plan.name),
                          _row(context, 'Precio',
                              '${formatMoney(plan.price, currency: plan.currency)} / ${planPeriodLabel(plan.durationMonths)}'),
                          _row(context, 'Citas', planAppointmentsLabel(plan)),
                          if (end != null)
                            _row(context, 'Vigente hasta', formatDate(end)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Get.offAllNamed(GetRoutes.home),
                    child: const Text('Comenzar a usar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
