import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/shared/widgets/app_code_field.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_layout.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Marco de auth rediseñado (12.05): encabezado de marca con el degradado de
/// la paleta, monograma, tarjeta del formulario y el código en seis cajas.
void main() {
  Future<void> pump(WidgetTester tester, Widget home,
      {ThemeData? theme}) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        MaterialApp(theme: theme ?? ThemeConfig.lightTheme, home: home));
  }

  testWidgets('marca, título en la tarjeta y sin "Volver" en el login',
      (tester) async {
    await pump(
        tester,
        const AuthLayout(
            title: '¡Bienvenido de vuelta!',
            subtitle: 'Inicia sesión para continuar',
            children: [Text('formulario')]));
    await tester.pumpAndSettle();
    expect(find.byType(AuthBrandHeader), findsOneWidget);
    expect(find.text('Agendity'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.byTooltip('Volver'), findsNothing);
    final card = find.byType(AppCard);
    expect(
        find.descendant(
            of: card, matching: find.text('¡Bienvenido de vuelta!')),
        findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('formulario')),
        findsOneWidget);
  });

  testWidgets('el encabezado usa el degradado de la paleta del tema',
      (tester) async {
    final rosa = ThemeConfig.of(AppPalette.rosa, AppThemeVariant.light);
    await pump(tester, const AuthLayout(title: 'x', children: []),
        theme: rosa);
    await tester.pumpAndSettle();
    final box = tester.widget<DecoratedBox>(find
        .descendant(
            of: find.byType(AuthBrandHeader),
            matching: find.byType(DecoratedBox))
        .first);
    expect((box.decoration as BoxDecoration).gradient,
        rosa.extension<AppTokens>()!.primaryGradient);
  });

  testWidgets('con onBack: flecha "Volver"', (tester) async {
    var back = 0;
    await pump(
        tester,
        AuthLayout(
            title: 'Recuperar contraseña',
            onBack: () => back++,
            children: const []),
        theme: ThemeConfig.darkTheme);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Volver'));
    expect(back, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('código: sigue siendo un PinCodeTextField de 6 cajas',
      (tester) async {
    final code = TextEditingController();
    addTearDown(code.dispose);
    String? completed;
    await pump(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: AppCodeField(
                controller: code, onCompleted: (v) => completed = v),
          ),
        ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PinCodeTextField), findsOneWidget);
    await tester.enterText(
        find.descendant(
            of: find.byType(PinCodeTextField),
            matching: find.byType(TextField)),
        '123456');
    await tester.pump(const Duration(milliseconds: 500));
    expect(code.text, '123456');
    expect(completed, '123456');
    expect(tester.takeException(), isNull);
  });
}
