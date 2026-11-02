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
}

class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  /// Inyectable en tests; por defecto, `SharedPreferences.getInstance`.
  final Future<SharedPreferences> Function() _preferences;

  ThemeLocalDataSourceImpl(
      {Future<SharedPreferences> Function()? preferences})
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
}
