import 'package:flutter/material.dart';
import 'package:login_signup/core/config/color_contrast.dart';
import 'package:login_signup/core/config/theme_config.dart';

/// Ilustración de los estados vacío y error (guía §3): ícono grande dentro de
/// un círculo con degradado y un halo suave. Con [tone] (error, éxito,
/// aviso…) el círculo lleva el tono en lugar de la paleta.
class StateIllustration extends StatelessWidget {
  final IconData icon;
  final AppTone? tone;

  const StateIllustration({super.key, required this.icon, this.tone});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final toneColors = tone == null ? null : tokens.tone(tone!);
    final gradient = toneColors == null
        ? tokens.primaryGradient
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [toneColors.container, toneColors.color],
          );
    // Sobre el tono, el texto legible en el centro del degradado (12.07:
    // antes era `onError` para todos los tonos y en oscuro el de éxito
    // quedaba granate sobre verde).
    final foreground = toneColors == null
        ? tokens.onGradient
        : readableOn(
            Color.lerp(toneColors.container, toneColors.color, 0.5)!);
    final halo = (toneColors?.color ?? tokens.gradientEnd);
    return ExcludeSemantics(
      child: Container(
        width: 132,
        height: 132,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: halo.withValues(alpha: 0.10),
        ),
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            border: Border.all(color: tokens.innerBorder),
            boxShadow: tokens.elevation2(tint: halo),
          ),
          child: Icon(icon, size: 48, color: foreground),
        ),
      ),
    );
  }
}
