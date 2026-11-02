import 'package:flutter/painting.dart';
import 'package:login_signup/common/enums/app_palette_enum.dart';

export 'package:login_signup/common/enums/app_palette_enum.dart';

/// Colores y nombre visible de cada paleta (D-22, guía de diseño §1). La
/// paleta es del dominio (`AppPalette`, sin colores); aquí vive lo visual.
/// Los tonos finales los ajusta `ThemeConfig` para cumplir el contraste AA.
extension AppPaletteColors on AppPalette {
  /// Semilla de la guía.
  Color get seed => switch (this) {
        AppPalette.lavanda => const Color(0xFF7C5CFC),
        AppPalette.rosa => const Color(0xFFEC4899),
        AppPalette.azul => const Color(0xFF2563EB),
        AppPalette.turquesa => const Color(0xFF0EA5A4),
        AppPalette.coral => const Color(0xFFF97316),
        AppPalette.grafito => const Color(0xFF334155),
      };

  /// Segundo color del degradado principal (arriba a la izquierda): un vecino
  /// del tono de la semilla, para que el degradado sea vivo sin perder la
  /// identidad de la paleta.
  Color get gradientPartner => switch (this) {
        AppPalette.lavanda => const Color(0xFFB04CF0),
        AppPalette.rosa => const Color(0xFFF43F5E),
        AppPalette.azul => const Color(0xFF0891B2),
        AppPalette.turquesa => const Color(0xFF10B981),
        AppPalette.coral => const Color(0xFFE11D48),
        AppPalette.grafito => const Color(0xFF475569),
      };

  /// Acento propio (solo grafito: dorado). `null` = el del esquema.
  Color? get accent => switch (this) {
        AppPalette.grafito => const Color(0xFFD4A017),
        _ => null,
      };

  /// Nombre visible ("Lavanda").
  String get label => switch (this) {
        AppPalette.lavanda => 'Lavanda',
        AppPalette.rosa => 'Rosa',
        AppPalette.azul => 'Azul',
        AppPalette.turquesa => 'Turquesa',
        AppPalette.coral => 'Coral',
        AppPalette.grafito => 'Grafito',
      };
}
