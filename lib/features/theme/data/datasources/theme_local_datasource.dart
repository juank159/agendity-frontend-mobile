import 'package:login_signup/features/theme/data/models/theme_preference_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Apariencia en `SharedPreferences` (el mismo almacenamiento que ya usaba
/// `ThemeController`): no está en el almacenamiento seguro porque no es un
/// secreto y así sobrevive al logout (`LocalStorage.clearAllData` borra solo
/// el almacenamiento seguro). Sin try/catch: los errores los traduce
/// `safeCall`.
abstract class ThemeLocalDataSource {
  Future<ThemePreferenceModel> read();

  Future<void> write(ThemePreferenceModel model);

  /// Última paleta del negocio vista en este equipo (`id`), para pintar con
  /// ella desde el arranque, antes de leer la configuración (12.03). `null` =
  /// ninguna o sin elegir.
  Future<String?> readBusinessPalette();

  /// `null` la borra.
  Future<void> writeBusinessPalette(String? paletteId);
}

class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  /// Inyectable en tests; por defecto, `SharedPreferences.getInstance`.
  final Future<SharedPreferences> Function() _preferences;

  ThemeLocalDataSourceImpl({Future<SharedPreferences> Function()? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance;

  @override
  Future<ThemePreferenceModel> read() async {
    final prefs = await _preferences();
    return ThemePreferenceModel(
      storedMode: prefs.getString(ThemePreferenceModel.modeKey),
      storedPalette: prefs.getString(ThemePreferenceModel.paletteKey),
    );
  }

  @override
  Future<void> write(ThemePreferenceModel model) async {
    final prefs = await _preferences();
    final mode = model.storedMode;
    if (mode != null) await prefs.setString(ThemePreferenceModel.modeKey, mode);
    final palette = model.storedPalette;
    if (palette == null) {
      await prefs.remove(ThemePreferenceModel.paletteKey);
    } else {
      await prefs.setString(ThemePreferenceModel.paletteKey, palette);
    }
  }

  @override
  Future<String?> readBusinessPalette() async =>
      (await _preferences()).getString(ThemePreferenceModel.businessPaletteKey);

  @override
  Future<void> writeBusinessPalette(String? paletteId) async {
    final prefs = await _preferences();
    if (paletteId == null) {
      await prefs.remove(ThemePreferenceModel.businessPaletteKey);
    } else {
      await prefs.setString(ThemePreferenceModel.businessPaletteKey, paletteId);
    }
  }
}
