import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/config/color_contrast.dart';
import 'package:login_signup/core/config/theme_config.dart';

/// 12.03: el texto principal y el de los botones cumplen AA (4,5:1) en las 6
/// paletas × claro/oscuro, y 7:1 en alto contraste. Si una semilla no llega,
/// `ThemeConfig` la oscurece o aclara (como la web de reservas).
void main() {
  test('contrastRatio: blanco/negro = 21, igual = 1', () {
    expect(contrastRatio(const Color(0xFFFFFFFF), const Color(0xFF000000)),
        closeTo(21, 0.01));
    expect(contrastRatio(const Color(0xFF7C5CFC), const Color(0xFF7C5CFC)),
        closeTo(1, 0.001));
  });

  test('ensureContrast oscurece sobre claro y aclara sobre oscuro', () {
    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);
    const coral = Color(0xFFF97316);
    expect(contrastRatio(coral, white), lessThan(contrastAA));
    final darker = ensureContrast(coral, white);
    expect(contrastRatio(darker, white), greaterThanOrEqualTo(contrastAA));
    expect(darker.computeLuminance(), lessThan(coral.computeLuminance()));
    // Conserva el tono.
    expect(HSLColor.fromColor(darker).hue,
        closeTo(HSLColor.fromColor(coral).hue, 2));

    const slate = Color(0xFF334155);
    final lighter = ensureContrast(slate, black, ratio: contrastAAA);
    expect(contrastRatio(lighter, black), greaterThanOrEqualTo(contrastAAA));
    // Ya cumple → igual.
    expect(ensureContrast(black, white), black);
  });

  for (final palette in AppPalette.values) {
    for (final variant in AppThemeVariant.values) {
      test('${palette.id} · ${variant.name}: contraste del texto y botones',
          () {
        final theme = ThemeConfig.of(palette, variant);
        final s = theme.colorScheme;
        final tokens = theme.extension<AppTokens>()!;
        final min =
            variant == AppThemeVariant.highContrast ? contrastAAA : contrastAA;

        void check(String what, Color fg, Color bg, [double? ratio]) {
          final value = contrastRatio(fg, bg);
          expect(value, greaterThanOrEqualTo(ratio ?? min),
              reason: '$what: ${value.toStringAsFixed(2)}');
        }

        // Texto principal sobre el fondo, las tarjetas y los campos.
        check('onSurface/surface', s.onSurface, s.surface);
        check(
            'onSurface/containerLowest', s.onSurface, s.surfaceContainerLowest);
        check('onSurface/containerHighest', s.onSurface,
            s.surfaceContainerHighest);
        check('onSurfaceVariant/surface', s.onSurfaceVariant, s.surface,
            contrastAA);
        // Botones: relleno (texto sobre primario), tonal, de texto y contorno
        // (primario sobre el fondo) y el principal con degradado.
        check('onPrimary/primary', s.onPrimary, s.primary);
        check('onPrimaryContainer/primaryContainer', s.onPrimaryContainer,
            s.primaryContainer, contrastAA);
        check('primary/surface', s.primary, s.surface);
        check('primary/containerLowest', s.primary, s.surfaceContainerLowest);
        check('onGradient/gradientStart', tokens.onGradient,
            tokens.gradientStart);
        check('onGradient/gradientEnd', tokens.onGradient, tokens.gradientEnd);
        check('onSecondaryContainer/secondaryContainer', s.onSecondaryContainer,
            s.secondaryContainer, contrastAA);
        check('onError/error', s.onError, s.error, contrastAA);
      });
    }
  }

  test('fuente empaquetada y tokens registrados en todos los temas', () {
    for (final palette in AppPalette.values) {
      for (final variant in AppThemeVariant.values) {
        final theme = ThemeConfig.of(palette, variant);
        expect(theme.textTheme.bodyMedium?.fontFamily, ThemeConfig.fontFamily);
        expect(theme.extension<AppTokens>(),
            ThemeConfig.tokensFor(palette, variant));
        expect(
            theme.brightness,
            variant == AppThemeVariant.light
                ? Brightness.light
                : Brightness.dark);
      }
    }
  });

  test('los tonos de estado no cambian con la paleta', () {
    for (final variant in AppThemeVariant.values) {
      final reference = ThemeConfig.tokensFor(AppPalette.lavanda, variant);
      for (final palette in AppPalette.values) {
        final tokens = ThemeConfig.tokensFor(palette, variant);
        expect(tokens.success, reference.success);
        expect(tokens.statusPending, reference.statusPending);
        expect(tokens.statusConfirmed, reference.statusConfirmed);
        expect(tokens.error, reference.error);
      }
    }
  });

  test('cada paleta tiene un primario distinto y el tema está en caché', () {
    final primaries = {
      for (final p in AppPalette.values)
        ThemeConfig.of(p, AppThemeVariant.light).colorScheme.primary,
    };
    expect(primaries, hasLength(AppPalette.values.length));
    expect(ThemeConfig.of(AppPalette.rosa, AppThemeVariant.dark),
        same(ThemeConfig.of(AppPalette.rosa, AppThemeVariant.dark)));
  });

  test('profundidad: dos capas, la segunda teñida con el color pedido', () {
    final tokens =
        ThemeConfig.tokensFor(AppPalette.azul, AppThemeVariant.light);
    const tint = Color(0xFF10B981);
    for (final shadows in [
      tokens.elevation1(tint: tint),
      tokens.elevation2(tint: tint),
      tokens.elevation3(tint: tint),
    ]) {
      expect(shadows, hasLength(2));
      expect(shadows[1].color.withValues(alpha: 1), tint);
    }
    expect(tokens.elevation3().first.blurRadius,
        greaterThan(tokens.elevation1().first.blurRadius));
    final dark = ThemeConfig.tokensFor(AppPalette.azul, AppThemeVariant.dark);
    // En oscuro, menos luz teñida y más borde visible sobre el fondo.
    expect(dark.tintedShadowOpacity, lessThan(tokens.tintedShadowOpacity));
  });
}
