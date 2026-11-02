import 'package:login_signup/features/theme/domain/entities/theme_preference.dart';

/// Forma guardada de la apariencia en `SharedPreferences`.
///
/// - Modo: clave [modeKey] (`app_theme`, la de siempre de `ThemeController`)
///   con el valor heredado `ThemeType.<id>` (`ThemeType.dark`). Se conserva
///   ese formato para que la elección de los usuarios actuales siga valiendo
///   sin migrar datos; también se lee el `id` suelto.
/// - Paleta: clave [paletteKey] con el `id` (`rosa`); sin clave = "usar la del
///   negocio".
class ThemePreferenceModel {
  static const String modeKey = 'app_theme';
  static const String paletteKey = 'app_palette';

  /// Última paleta del negocio (12.03): copia local para evitar el parpadeo
  /// al arrancar. No es una elección del dispositivo.
  static const String businessPaletteKey = 'app_business_palette';
  static const String _legacyModePrefix = 'ThemeType.';

  /// Valores crudos guardados (`null` = no hay).
  final String? storedMode;
  final String? storedPalette;

  const ThemePreferenceModel({this.storedMode, this.storedPalette});

  factory ThemePreferenceModel.fromEntity(ThemePreference preference) =>
      ThemePreferenceModel(
        storedMode: '$_legacyModePrefix${preference.mode.id}',
        storedPalette: preference.palette?.id,
      );

  /// Valores ilegibles → los de una instalación nueva.
  ThemePreference toEntity() {
    final mode = storedMode;
    return ThemePreference(
      palette: AppPalette.fromId(storedPalette),
      mode: ThemeModePreference.fromId(
              mode != null && mode.startsWith(_legacyModePrefix)
                  ? mode.substring(_legacyModePrefix.length)
                  : mode) ??
          ThemeModePreference.fallback,
    );
  }
}
