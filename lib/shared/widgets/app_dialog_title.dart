import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';

/// Título de hojas y diálogos con formulario (guía §3, 12.07): ícono en un
/// círculo con el degradado de la paleta, título w700 (encabezado para
/// lectores de pantalla), subtítulo opcional y una acción a la derecha
/// (p. ej. "Cerrar").
///
/// Lo usan `AppSheet` y los diálogos de cita, pago, reembolso y selección
/// (profesional, servicios, cliente). Los avisos con un solo mensaje usan
/// `AppDialog`.
class AppDialogTitle extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppDialogTitle({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final leading = icon;
    final sub = subtitle;
    final action = trailing;
    return Row(
      children: [
        if (leading != null) ...[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: tokens.primaryGradient,
              border: Border.all(color: tokens.innerBorder),
              boxShadow: tokens.elevation1(tint: tokens.gradientEnd),
            ),
            child: Icon(leading, size: 21, color: tokens.onGradient),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (sub != null && sub.isNotEmpty)
                Text(sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        if (action != null) action,
      ],
    );
  }
}
