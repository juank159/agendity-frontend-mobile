import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:login_signup/core/config/theme_config.dart';

enum ThemeType { light, dark, highContrast, system }

/// Preferencia de tema de la app. Registro **único** en
/// `core/di/init_dependencies.dart` (permanente: el tema sobrevive al logout).
///
/// No cambia el tema por su cuenta: `main.dart` lee [themeMode] y [darkTheme]
/// dentro de un `GetX<ThemeController>` y reconstruye `GetMaterialApp`.
class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  static const String themeKey = 'app_theme';

  final _themeType = ThemeType.light.obs;

  ThemeType get themeType => _themeType.value;

  ThemeMode get themeMode {
    switch (_themeType.value) {
      case ThemeType.light:
        return ThemeMode.light;
      case ThemeType.dark:
      case ThemeType.highContrast:
        return ThemeMode.dark;
      case ThemeType.system:
        return ThemeMode.system;
    }
  }

  /// El alto contraste es un tema oscuro alternativo.
  ThemeData get darkTheme => _themeType.value == ThemeType.highContrast
      ? ThemeConfig.highContrastTheme
      : ThemeConfig.darkTheme;

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(themeKey);
    if (saved == null) return;
    _themeType.value = ThemeType.values.firstWhere(
      (type) => type.toString() == saved,
      orElse: () => ThemeType.light,
    );
  }

  Future<void> setTheme(ThemeType type) async {
    _themeType.value = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeKey, type.toString());
  }

  bool isCurrentTheme(ThemeType type) => _themeType.value == type;
}
