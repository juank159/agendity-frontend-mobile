import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Contraste de color según WCAG 2.x (12.03). Lo usa `ThemeConfig` para que
/// los colores de cada paleta cumplan AA (4,5:1 en texto normal) aunque la
/// semilla no llegue: la oscurece o la aclara sin cambiar su tono, como hace
/// la web de reservas del backend.

/// Mínimo AA para texto normal.
const double contrastAA = 4.5;

/// Mínimo AAA para texto normal (alto contraste).
const double contrastAAA = 7.0;

/// Relación de contraste entre [a] y [b] (de 1 a 21). Ignora la opacidad.
double contrastRatio(Color a, Color b) {
  final la = a.withValues(alpha: 1).computeLuminance();
  final lb = b.withValues(alpha: 1).computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// [color] con la luminosidad justa para llegar a [ratio] sobre [against]:
/// lo oscurece si [against] es claro y lo aclara si es oscuro. Conserva tono
/// y saturación (HSL). Si ya cumple, lo devuelve igual.
Color ensureContrast(Color color, Color against, {double ratio = contrastAA}) {
  if (contrastRatio(color, against) >= ratio) return color;
  final darken = against.computeLuminance() > 0.18;
  final hsl = HSLColor.fromColor(color);
  var lightness = hsl.lightness;
  for (var i = 0; i < 100; i++) {
    lightness = (lightness + (darken ? -0.01 : 0.01)).clamp(0.0, 1.0);
    final candidate = hsl.withLightness(lightness).toColor();
    if (contrastRatio(candidate, against) >= ratio) return candidate;
    if (lightness == 0 || lightness == 1) break;
  }
  return darken ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
}

/// Texto blanco sobre un color (de datos o de la paleta).
const Color textWhite = Color(0xFFFFFFFF);

/// Texto casi negro sobre un color claro.
const Color textInk = Color(0xFF111111);

/// Blanco o casi negro, el que más contraste dé sobre [background].
Color readableOn(Color background) =>
    contrastRatio(textWhite, background) >= contrastRatio(textInk, background)
        ? textWhite
        : textInk;

/// [color] con el tono girado [degrees] grados (para el degradado).
Color shiftHue(Color color, double degrees) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withHue((hsl.hue + degrees) % 360).toColor();
}
