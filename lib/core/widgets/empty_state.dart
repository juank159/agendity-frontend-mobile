import 'package:flutter/material.dart';
import 'package:login_signup/core/widgets/state_illustration.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';

/// Estado vacío de una lista (guía §3): ilustración con degradado, texto
/// amable y una acción. Ver también [ListStateView].
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subMessage;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData? actionIcon;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subMessage,
    this.onAction,
    this.actionLabel,
    this.actionIcon,
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
            StateIllustration(icon: icon),
            const SizedBox(height: 20),
            Text(
              message,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subMessage!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              AppGradientButton(
                label: actionLabel!,
                icon: actionIcon,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
