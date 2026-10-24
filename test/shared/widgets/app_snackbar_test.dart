import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

Future<void> _pumpApp(WidgetTester tester, {ThemeData? theme}) async {
  await tester.pumpWidget(GetMaterialApp(
    theme: theme ?? ThemeConfig.lightTheme,
    home: const Scaffold(body: Text('home')),
  ));
}

/// Deja pasar la duración y la animación de salida (sin timers pendientes).
Future<void> _expire(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Color? _background(WidgetTester tester) =>
    tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor;

void main() {
  tearDown(Get.reset);

  testWidgets('success usa el tono de éxito del tema', (tester) async {
    await _pumpApp(tester);
    AppSnackbar.success('Cita creada');
    await tester.pumpAndSettle();
    expect(find.text('Listo'), findsOneWidget);
    expect(find.text('Cita creada'), findsOneWidget);
    expect(_background(tester), AppTokens.light.success.container);
    await _expire(tester);
    expect(find.text('Cita creada'), findsNothing);
  });

  testWidgets('error e info con su título y tono', (tester) async {
    await _pumpApp(tester);
    AppSnackbar.error('Sin conexión');
    await tester.pumpAndSettle();
    expect(find.text('Error'), findsOneWidget);
    expect(_background(tester), AppTokens.light.error.container);
    await _expire(tester);

    AppSnackbar.info('Hay cambios', title: 'Novedad');
    await tester.pumpAndSettle();
    expect(find.text('Novedad'), findsOneWidget);
    expect(_background(tester), AppTokens.light.info.container);
    await _expire(tester);
  });

  testWidgets('en modo oscuro usa los tokens oscuros', (tester) async {
    await _pumpApp(tester, theme: ThemeConfig.darkTheme);
    AppSnackbar.warning('Revisa el horario');
    await tester.pumpAndSettle();
    expect(_background(tester), AppTokens.dark.warning.container);
    await _expire(tester);
  });

  testWidgets('un mensaje nuevo sustituye al anterior', (tester) async {
    await _pumpApp(tester);
    AppSnackbar.info('primero');
    await tester.pumpAndSettle();
    AppSnackbar.success('segundo');
    await tester.pumpAndSettle();
    expect(find.text('primero'), findsNothing);
    expect(find.text('segundo'), findsOneWidget);
    await _expire(tester);
  });
}
