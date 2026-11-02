import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/theme/domain/entities/theme_preference.dart';
import 'package:login_signup/features/theme/presentation/screens/theme_settings_screen.dart';
import 'package:login_signup/features/theme/theme_dependencies.dart';
import 'package:login_signup/shared/controllers/theme_controller.dart';
import 'package:login_signup/shared/widgets/palette_swatch.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Apariencia" (D-22, 12.03): muestras de las 6 paletas, "Usar el del
/// negocio", modo y vista previa en vivo (el tema de la app cambia al tocar).
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThemeDependencies.init();
  });

  tearDown(Get.reset);

  Future<ThemeController> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = Get.put(ThemeController(), permanent: true);
    await tester.pumpWidget(GetX<ThemeController>(
      builder: (c) => GetMaterialApp(
        theme: c.theme,
        darkTheme: c.darkTheme,
        themeMode: c.themeMode,
        home: const ThemeSettingsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    return controller;
  }

  bool selected(WidgetTester tester, AppPalette palette) => tester
      .widget<PaletteSwatch>(find.ancestor(
          of: find.byKey(Key('palette-${palette.id}')),
          matching: find.byType(PaletteSwatch)))
      .selected;

  testWidgets('muestra las 6 paletas, el modo y la vista previa',
      (tester) async {
    await pump(tester);
    expect(find.text('Apariencia'), findsOneWidget);
    for (final palette in AppPalette.values) {
      expect(find.byKey(Key('palette-${palette.id}')), findsOneWidget);
      expect(find.text(palette.label), findsWidgets);
    }
    for (final title in [
      'Tema claro',
      'Tema oscuro',
      'Tema del sistema',
      'Alto contraste',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Usar el del negocio'), findsOneWidget);
    // Vista previa: mini cita en 12 h y botones.
    expect(find.text('Paula Gómez'), findsOneWidget);
    expect(find.text('10:00 – 11:05 a. m.'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
  });

  testWidgets('tocar una muestra cambia el tema de la app y se guarda',
      (tester) async {
    final controller = await pump(tester);
    await tester.tap(find.byKey(const Key('palette-turquesa')));
    await tester.pumpAndSettle();

    expect(controller.palette, AppPalette.turquesa);
    expect(selected(tester, AppPalette.turquesa), isTrue);
    final context = tester.element(find.byType(ThemeSettingsScreen));
    expect(
        Theme.of(context).colorScheme.primary,
        ThemeConfig.of(AppPalette.turquesa, AppThemeVariant.light)
            .colorScheme
            .primary);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_palette'), 'turquesa');
  });

  testWidgets('"Usar el del negocio" vuelve a la paleta del negocio',
      (tester) async {
    final controller = await pump(tester);
    controller.applyBusinessSettings(const BusinessSettings(
        timeZone: 'America/Bogota', themePalette: AppPalette.coral));
    await tester.tap(find.byKey(const Key('palette-azul')));
    await tester.pumpAndSettle();
    expect(controller.palette, AppPalette.azul);

    await tester.tap(find.byKey(const Key('palette-business')));
    await tester.pumpAndSettle();
    expect(controller.usesBusinessPalette, isTrue);
    expect(controller.palette, AppPalette.coral);
    // Ninguna muestra marcada: manda el negocio (Coral).
    for (final palette in AppPalette.values) {
      expect(selected(tester, palette), isFalse);
    }
    expect(find.text('Coral'), findsWidgets);
  });

  testWidgets('modo oscuro y alto contraste se aplican al instante',
      (tester) async {
    final controller = await pump(tester);
    await tester.tap(find.text('Tema oscuro'));
    await tester.pumpAndSettle();
    expect(controller.mode, ThemeModePreference.dark);
    var context = tester.element(find.byType(ThemeSettingsScreen));
    expect(Theme.of(context).brightness, Brightness.dark);

    await tester.tap(find.text('Alto contraste'));
    await tester.pumpAndSettle();
    context = tester.element(find.byType(ThemeSettingsScreen));
    expect(
        Theme.of(context).colorScheme.surface,
        ThemeConfig.of(AppPalette.lavanda, AppThemeVariant.highContrast)
            .colorScheme
            .surface);
  });
}
