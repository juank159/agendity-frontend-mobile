import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';

/// Aviso tonal dentro de una pantalla o diálogo (información, aviso, error o
/// éxito): fondo del contenedor del tono, ícono opcional y texto. Los colores
/// salen de `context.tokens.tone`, que no cambian con la paleta.
class AppNote extends StatelessWidget {
  final String text;
  final AppTone tone;
  final IconData? icon;

  /// Contenido extra bajo el texto (p. ej. un botón).
  final Widget? trailing;
  final EdgeInsetsGeometry margin;

  const AppNote(
    this.text, {
    super.key,
    required this.tone,
    this.icon,
    this.trailing,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.tone(tone);
    final noteIcon = icon;
    final extra = trailing;
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: AppRadii.fieldRadius,
        border: Border.all(color: colors.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (noteIcon != null) ...[
            Icon(noteIcon, size: 20, color: colors.onContainer),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colors.onContainer, height: 1.4)),
                if (extra != null) ...[const SizedBox(height: 8), extra],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
