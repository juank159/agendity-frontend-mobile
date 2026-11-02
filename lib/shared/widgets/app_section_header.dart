import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';

/// Encabezado de sección (guía §3): ícono en una píldora tonal, título w700,
/// subtítulo opcional y una acción a la derecha ("Ver todo").
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final sectionIcon = icon;
    final label = actionLabel;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (sectionIcon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: AppRadii.chipRadius,
              ),
              child:
                  Icon(sectionIcon, size: 18, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: text.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          if (label != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(label)),
        ],
      ),
    );
  }
}
