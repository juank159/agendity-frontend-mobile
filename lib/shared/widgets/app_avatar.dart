import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';

/// Avatar de la guía (§3): iniciales sobre el degradado de la paleta, con
/// borde interior claro; la foto si hay [imageUrl] (y las iniciales si falla).
/// [muted] = apagado (p. ej. un profesional inactivo).
class AppAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double radius;
  final bool muted;

  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 24,
    this.muted = false,
  });

  /// Hasta dos iniciales: "Ana María Pérez" → "AP"; "ana" → "A"; vacío → "?".
  static String initialsOf(String name) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    final first = words.first.characters.first;
    final last = words.length > 1 ? words.last.characters.first : '';
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final size = radius * 2;
    final foreground = muted ? scheme.onSurfaceVariant : tokens.onGradient;
    final initials = Center(
      child: Text(
        initialsOf(name),
        maxLines: 1,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.72,
          height: 1,
        ),
      ),
    );
    final image = imageUrl;
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: muted ? null : tokens.primaryGradient,
          color: muted ? scheme.surfaceContainerHighest : null,
          border: Border.all(color: tokens.innerBorder),
          boxShadow: muted ? null : tokens.elevation1(),
        ),
        child: ClipOval(
          child: image != null && image.isNotEmpty
              ? Image.network(
                  image,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => initials,
                )
              : initials,
        ),
      ),
    );
  }
}
