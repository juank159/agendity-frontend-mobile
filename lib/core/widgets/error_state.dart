import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/state_illustration.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';

/// Estado de error de una pantalla o lista (guía §3): ilustración en el tono
/// de error, texto y "Reintentar". Sin [onRetry] no hay botón.
/// Ver también [ListStateView].
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String title;
  final String actionLabel;
  final IconData actionIcon;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Ocurrió un error',
    this.actionLabel = 'Reintentar',
    this.actionIcon = Icons.refresh_rounded,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateIllustration(icon: icon, tone: AppTone.error),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppGradientButton(
                label: actionLabel,
                icon: actionIcon,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
