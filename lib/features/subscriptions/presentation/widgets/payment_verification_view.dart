import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/core/widgets/state_illustration.dart';
import '../controllers/subscription_controller.dart';

/// Resultado de la verificación del pago al volver del checkout.
class PaymentVerificationView extends GetView<SubscriptionController> {
  /// "Volver a los planes".
  final VoidCallback onBackToPlans;

  /// "Ir al inicio".
  final VoidCallback onGoHome;

  /// Verificar otra vez.
  final VoidCallback onVerify;

  const PaymentVerificationView({
    super.key,
    required this.onBackToPlans,
    required this.onGoHome,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final message = controller.verificationMessage.value;
      switch (controller.verification.value) {
        case PaymentVerificationStatus.pending:
          return _VerificationMessage(
            icon: Icons.hourglass_top_rounded,
            tone: AppTone.warning,
            title: 'Pago en proceso',
            message: message,
            primaryLabel: 'Verificar de nuevo',
            onPrimary: onVerify,
            secondaryLabel: 'Ir al inicio',
            onSecondary: onGoHome,
          );
        case PaymentVerificationStatus.failed:
          return _VerificationMessage(
            icon: Icons.cancel_rounded,
            tone: AppTone.error,
            title: 'Pago no confirmado',
            message: message,
            primaryLabel: 'Volver a los planes',
            onPrimary: onBackToPlans,
            secondaryLabel: 'Verificar de nuevo',
            onSecondary: onVerify,
          );
        case PaymentVerificationStatus.error:
          return _VerificationMessage(
            icon: Icons.error_outline_rounded,
            tone: AppTone.error,
            title: 'No se pudo verificar el pago',
            message: message,
            primaryLabel: 'Reintentar verificación',
            onPrimary: onVerify,
            secondaryLabel: 'Volver a los planes',
            onSecondary: onBackToPlans,
          );
        case PaymentVerificationStatus.idle:
        case PaymentVerificationStatus.verifying:
        case PaymentVerificationStatus.approved:
          return const LoadingState(
              message: 'Verificando pago…', skeleton: false);
      }
    });
  }
}

class _VerificationMessage extends StatelessWidget {
  final IconData icon;
  final AppTone tone;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  const _VerificationMessage({
    required this.icon,
    required this.tone,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AppFadeIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: StateIllustration(icon: icon, tone: tone)),
                const SizedBox(height: 20),
                Semantics(
                  header: true,
                  child: Text(title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 8),
                Text(message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                AppGradientButton(
                  label: primaryLabel,
                  expand: true,
                  onPressed: onPrimary,
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
