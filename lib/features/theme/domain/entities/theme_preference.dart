import 'package:login_signup/common/enums/app_palette_enum.dart';

export 'package:login_signup/common/enums/app_palette_enum.dart';

/// Modo de la app en este dispositivo (D-22: el modo es siempre del
/// dispositivo, nunca del negocio). El alto contraste es un modo propio.
enum ThemeModePreference {
  light('light'),
  dark('dark'),
  system('system'),
  highContrast('highContrast');

  const ThemeModePreference(this.id);

  /// Valor estable que se guarda en el dispositivo.
  final String id;

  /// El de una instalación nueva (el de siempre de la app).
  static const ThemeModePreference fallback = ThemeModePreference.light;

  /// `id` → modo; desconocido o `null` → `null`.
  static ThemeModePreference? fromId(Object? value) {
    if (value is! String) return null;
    final id = value.trim();
    for (final mode in values) {
      if (mode.id == id) return mode;
    }
    return null;
  }
}

/// Preferencia de apariencia guardada en el dispositivo (D-22): la paleta
/// elegida aquí (`null` = "usar la del negocio") y el modo.
///
/// La paleta que se pinta la decide `resolvePalette(palette, negocio)`.
class ThemePreference {
  /// `null` = el dispositivo no eligió paleta: manda la del negocio y, si
  /// tampoco hay, lavanda.
  final AppPalette? palette;

  final ThemeModePreference mode;

  const ThemePreference({
    this.palette,
    this.mode = ThemeModePreference.fallback,
  });

  /// Sin nada guardado: sin paleta propia y modo claro.
  static const ThemePreference initial = ThemePreference();

  bool get usesBusinessPalette => palette == null;

  /// [usesBusinessPalette] = `true` quita la paleta propia (no se puede con
  /// `palette: null`).
  ThemePreference copyWith({
    AppPalette? palette,
    ThemeModePreference? mode,
    bool usesBusinessPalette = false,
  }) =>
      ThemePreference(
        palette: usesBusinessPalette ? null : palette ?? this.palette,
        mode: mode ?? this.mode,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemePreference &&
          other.palette == palette &&
          other.mode == mode;

  @override
  int get hashCode => Object.hash(palette, mode);

  @override
  String toString() => 'ThemePreference(palette: ${palette?.id}, mode: ${mode.id})';
}
