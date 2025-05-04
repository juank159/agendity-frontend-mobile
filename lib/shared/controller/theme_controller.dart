// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import 'package:login_signup/core/config/theme_config.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// enum ThemeType { light, dark, highContrast, system }

// class ThemeController extends GetxController {
//   static ThemeController get to => Get.find();

//   // Variables observables
//   final _themeType = ThemeType.light.obs;
//   final _isDarkMode = false.obs;

//   // Getters
//   ThemeType get themeType => _themeType.value;
//   bool get isDarkMode => _isDarkMode.value;

//   // Referencias para shared preferences
//   static const String themeKey = 'app_theme';
//   SharedPreferences? _prefs;

//   @override
//   void onInit() {
//     super.onInit();
//     _loadThemeFromPrefs();
//   }

//   // Cargar el tema guardado cuando inicia la app
//   Future<void> _loadThemeFromPrefs() async {
//     _prefs = await SharedPreferences.getInstance();
//     final savedTheme = _prefs?.getString(themeKey);

//     if (savedTheme != null) {
//       final type = ThemeType.values.firstWhere(
//         (e) => e.toString() == savedTheme,
//         orElse: () => ThemeType.light,
//       );
//       _themeType.value = type;

//       if (type == ThemeType.system) {
//         _setSystemTheme();
//       } else {
//         _updateTheme(type);
//       }
//     } else {
//       // Por defecto usar tema claro
//       _themeType.value = ThemeType.light;
//       _updateTheme(ThemeType.light);
//     }
//   }

//   // Actualizar el tema de la aplicación
//   void setTheme(ThemeType type) {
//     _themeType.value = type;
//     _saveThemePreference(type);

//     if (type == ThemeType.system) {
//       _setSystemTheme();
//     } else {
//       _updateTheme(type);
//     }
//   }

//   // Seguir el tema del sistema
//   void _setSystemTheme() {
//     final brightness = Get.mediaQuery.platformBrightness;
//     _isDarkMode.value = brightness == Brightness.dark;
//     Get.changeThemeMode(
//         brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light);
//   }

//   // Actualizar el tema actual
//   void _updateTheme(ThemeType type) {
//     switch (type) {
//       case ThemeType.light:
//         Get.changeThemeMode(ThemeMode.light);
//         _isDarkMode.value = false;
//         break;
//       case ThemeType.dark:
//         Get.changeThemeMode(ThemeMode.dark);
//         _isDarkMode.value = true;
//         break;
//       case ThemeType.highContrast:
//         Get.changeTheme(ThemeConfig.highContrastTheme);
//         _isDarkMode.value = true;
//         break;
//       case ThemeType.system:
//         // Ya se maneja en _setSystemTheme
//         break;
//     }
//   }

//   // Guardar la preferencia del tema
//   Future<void> _saveThemePreference(ThemeType type) async {
//     _prefs ??= await SharedPreferences.getInstance();
//     await _prefs?.setString(themeKey, type.toString());
//   }

//   // Alternar entre tema claro y oscuro
//   void toggleTheme() {
//     if (_themeType.value == ThemeType.light) {
//       setTheme(ThemeType.dark);
//     } else {
//       setTheme(ThemeType.light);
//     }
//   }

//   // Verificar si el tema actual coincide con el proporcionado
//   bool isCurrentTheme(ThemeType type) {
//     return _themeType.value == type;
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:login_signup/core/config/theme_config.dart';

enum ThemeType { light, dark, highContrast, system }

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  // Variables observables
  final _themeType = ThemeType.light.obs;
  final _isDarkMode = false.obs;

  // Getters
  ThemeType get themeType => _themeType.value;
  bool get isDarkMode => _isDarkMode.value;

  // Referencias para shared preferences
  static const String themeKey = 'app_theme';
  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromPrefs();
  }

  // Cargar el tema guardado cuando inicia la app
  Future<void> _loadThemeFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs?.getString(themeKey);

    if (savedTheme != null) {
      final type = ThemeType.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemeType.light,
      );
      _themeType.value = type;

      if (type == ThemeType.system) {
        _setSystemTheme();
      } else {
        _updateTheme(type);
      }
    } else {
      // Por defecto usar tema claro
      _themeType.value = ThemeType.light;
      _updateTheme(ThemeType.light);
    }
  }

  // Actualizar el tema de la aplicación
  void setTheme(ThemeType type) {
    _themeType.value = type;
    _saveThemePreference(type);

    if (type == ThemeType.system) {
      _setSystemTheme();
    } else {
      _updateTheme(type);
    }
  }

  // Seguir el tema del sistema
  void _setSystemTheme() {
    final brightness = Get.mediaQuery.platformBrightness;
    _isDarkMode.value = brightness == Brightness.dark;
    Get.changeThemeMode(
        brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light);
  }

  // Actualizar el tema actual
  void _updateTheme(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        Get.changeThemeMode(ThemeMode.light);
        _isDarkMode.value = false;
        break;
      case ThemeType.dark:
        Get.changeThemeMode(ThemeMode.dark);
        _isDarkMode.value = true;
        break;
      case ThemeType.highContrast:
        Get.changeTheme(ThemeConfig.highContrastTheme);
        _isDarkMode.value = true;
        break;
      case ThemeType.system:
        // Ya se maneja en _setSystemTheme
        break;
    }
  }

  // Guardar la preferencia del tema
  Future<void> _saveThemePreference(ThemeType type) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(themeKey, type.toString());
  }

  // Alternar entre tema claro y oscuro
  void toggleTheme() {
    if (_themeType.value == ThemeType.light) {
      setTheme(ThemeType.dark);
    } else {
      setTheme(ThemeType.light);
    }
  }

  // Verificar si el tema actual coincide con el proporcionado
  bool isCurrentTheme(ThemeType type) {
    return _themeType.value == type;
  }
}
