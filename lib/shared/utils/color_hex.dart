import 'package:flutter/material.dart';

/// Color por defecto de un dato sin color válido (= `ServiceEntity.defaultColor`).
const Color defaultDataColor = Color(0xFF1C94F4);

/// `Color` → `#rrggbb` (como se guardan los colores de los servicios).
String colorToHex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// `#rrggbb` o `#rgb` → `Color`. Vacío o inválido → [fallback].
///
/// Lo usan services (color del servicio) y appointments (color de la cita en
/// la agenda).
Color colorFromHex(String? hex, {Color fallback = defaultDataColor}) {
  var digits = (hex ?? '').trim().replaceFirst('#', '');
  if (digits.length == 3) {
    digits = digits.split('').map((c) => '$c$c').join();
  }
  final value = digits.length == 6 ? int.tryParse(digits, radix: 16) : null;
  return value == null ? fallback : Color(0xFF000000 | value);
}

/// Blanco o negro, lo que se lea mejor sobre [color] (un color de datos, no
/// del tema: p. ej. el de un servicio).
Color contrastOn(Color color) =>
    ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);
