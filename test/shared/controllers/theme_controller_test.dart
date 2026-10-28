import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/shared/controllers/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('alto contraste = darkTheme alternativo con ThemeMode.dark', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController();
    await controller.setTheme(ThemeType.highContrast);
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.darkTheme, same(ThemeConfig.highContrastTheme));

    await controller.setTheme(ThemeType.dark);
    expect(controller.darkTheme, same(ThemeConfig.darkTheme));
    await controller.setTheme(ThemeType.system);
    expect(controller.themeMode, ThemeMode.system);
  });

  test('guarda y recupera la preferencia', () async {
    SharedPreferences.setMockInitialValues(
        {ThemeController.themeKey: ThemeType.dark.toString()});
    final controller = ThemeController()..onInit();
    await Future<void>.delayed(Duration.zero);
    expect(controller.themeType, ThemeType.dark);

    await controller.setTheme(ThemeType.light);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ThemeController.themeKey), 'ThemeType.light');
  });

  test('los tres temas registran los tokens', () {
    expect(ThemeConfig.lightTheme.extension<AppTokens>(), AppTokens.light);
    expect(ThemeConfig.darkTheme.extension<AppTokens>(), AppTokens.dark);
    expect(ThemeConfig.highContrastTheme.extension<AppTokens>(),
        AppTokens.highContrast);
  });
}
