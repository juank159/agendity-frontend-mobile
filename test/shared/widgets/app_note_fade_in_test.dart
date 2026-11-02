import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/shared/widgets/app_note.dart';

/// Kit de 12.05: aviso tonal y entrada de listas.
void main() {
  Widget app(Widget child, {bool disableAnimations = false}) => MaterialApp(
        theme: ThemeConfig.lightTheme,
        darkTheme: ThemeConfig.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(body: child),
        ),
      );

  group('AppNote', () {
    testWidgets('texto, ícono y color del tono', (tester) async {
      await tester.pumpWidget(app(const AppNote('Sin conexión',
          tone: AppTone.warning, icon: Icons.cloud_off_rounded)));
      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      final context = tester.element(find.byType(AppNote));
      final box = tester.widget<Container>(find.descendant(
          of: find.byType(AppNote), matching: find.byType(Container)));
      expect((box.decoration! as BoxDecoration).color,
          context.tokens.warning.container);
    });

    testWidgets('sin ícono y con contenido extra', (tester) async {
      await tester.pumpWidget(app(AppNote('Aviso',
          tone: AppTone.info,
          trailing: TextButton(onPressed: () {}, child: const Text('Ver')))));
      expect(find.byType(Icon), findsNothing);
      expect(find.text('Ver'), findsOneWidget);
    });

    testWidgets('en oscuro también se pinta', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeConfig.darkTheme,
        home: const Scaffold(
            body: AppNote('Error', tone: AppTone.error, icon: Icons.error_rounded)),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('AppFadeIn', () {
    double opacity(WidgetTester tester) => tester
        .widget<Opacity>(find.descendant(
            of: find.byType(AppFadeIn), matching: find.byType(Opacity)))
        .opacity;

    testWidgets('entra con desvanecido y termina visible', (tester) async {
      await tester.pumpWidget(app(const AppFadeIn(index: 3, child: Text('x'))));
      expect(opacity(tester), 0);
      await tester.pump(const Duration(milliseconds: 100));
      // El tercero espera 120 ms: aún no ha empezado.
      expect(opacity(tester), 0);
      await tester.pumpAndSettle();
      expect(opacity(tester), 1);
      expect(find.text('x'), findsOneWidget);
    });

    testWidgets('sin animaciones: el hijo tal cual', (tester) async {
      await tester.pumpWidget(app(const AppFadeIn(child: Text('x')),
          disableAnimations: true));
      expect(find.byType(Opacity), findsNothing);
      expect(find.text('x'), findsOneWidget);
    });

    testWidgets('se puede tocar mientras entra', (tester) async {
      var taps = 0;
      await tester.pumpWidget(app(AppFadeIn(
          child: TextButton(onPressed: () => taps++, child: const Text('Ir')))));
      await tester.tap(find.text('Ir'));
      expect(taps, 1);
      await tester.pumpAndSettle();
    });
  });
}
