import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/shared/widgets/app_dialog_title.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(GetMaterialApp(
    theme: ThemeConfig.lightTheme,
    home: const Scaffold(body: Text('home')),
    getPages: [
      GetPage(
        name: GetRoutes.subscriptionPlans,
        page: () => const Scaffold(body: Text('planes')),
      ),
    ],
  ));
}

void main() {
  tearDown(Get.reset);

  testWidgets('AppDialogs.retry: "Reintentar" → true, "Ahora no" → false',
      (tester) async {
    await _pumpApp(tester);
    var result = AppDialogs.retry(title: 'No se envió', message: 'SMTP');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);

    result = AppDialogs.retry(title: 'No se envió', message: 'SMTP');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });

  group('AppDialogs.confirm', () {
    testWidgets('devuelve true al confirmar', (tester) async {
      await _pumpApp(tester);
      final result = AppDialogs.confirm(
        title: '¿Eliminar?',
        message: 'No se puede deshacer',
        confirmLabel: 'Eliminar',
        destructive: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar?'), findsOneWidget);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(find.text('¿Eliminar?'), findsNothing);
    });

    testWidgets('devuelve false al cancelar', (tester) async {
      await _pumpApp(tester);
      final result = AppDialogs.confirm(title: 'T', message: 'M');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });

    testWidgets(
        '12.07: confirmar normal = botón con degradado (AppGradientButton) e '
        'ícono _rounded', (tester) async {
      await _pumpApp(tester);
      final result = AppDialogs.confirm(title: 'T', message: 'M');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppGradientButton, 'Confirmar'),
          findsOneWidget);
      // Sigue siendo un FilledButton para los tests de integración.
      expect(find.widgetWithText(FilledButton, 'Confirmar'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    });

    testWidgets(
        '12.07: destructivo = FilledButton del color de error, sin degradado',
        (tester) async {
      await _pumpApp(tester);
      final result = AppDialogs.confirm(
          title: '¿Eliminar?',
          message: 'M',
          confirmLabel: 'Eliminar',
          destructive: true);
      await tester.pumpAndSettle();
      expect(find.byType(AppGradientButton), findsNothing);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      final button = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Eliminar'));
      final context = tester.element(find.text('Eliminar'));
      expect(button.style?.backgroundColor?.resolve({}),
          Theme.of(context).colorScheme.error);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });

    testWidgets('12.07: error e info usan íconos _rounded', (tester) async {
      await _pumpApp(tester);
      AppDialogs.error(message: 'Falló');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      AppDialogs.info(title: 'I', message: 'M');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
    });

    testWidgets('devuelve false al tocar fuera', (tester) async {
      await _pumpApp(tester);
      final result = AppDialogs.confirm(title: 'T', message: 'M');
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });
  });

  testWidgets('AppDialogs.error muestra el mensaje y se cierra', (tester) async {
    await _pumpApp(tester);
    final done = AppDialogs.error(message: 'Falló algo');
    await tester.pumpAndSettle();
    expect(find.text('Ocurrió un error'), findsOneWidget);
    expect(find.text('Falló algo'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    await done;
    expect(find.text('Falló algo'), findsNothing);
  });

  testWidgets('AppDialogs.info muestra el detalle', (tester) async {
    await _pumpApp(tester);
    AppDialogs.info(
      title: 'Horario no disponible',
      message: 'El profesional no está disponible.',
      detail: 'Elige otra hora.',
      tone: AppTone.warning,
    );
    await tester.pumpAndSettle();
    expect(find.text('Horario no disponible'), findsOneWidget);
    expect(find.text('Elige otra hora.'), findsOneWidget);
  });

  group('AppDialogs.subscriptionRequired', () {
    testWidgets('Owner: fin del trial y "Ver planes" navega', (tester) async {
      await _pumpApp(tester);
      AppDialogs.subscriptionRequired(canManagePlans: true);
      await tester.pumpAndSettle();
      expect(find.text('Plan de prueba finalizado'), findsOneWidget);
      await tester.tap(find.text('Ver planes disponibles'));
      await tester.pumpAndSettle();
      expect(find.text('planes'), findsOneWidget);
    });

    testWidgets('Owner: "Ahora no" no navega', (tester) async {
      await _pumpApp(tester);
      AppDialogs.subscriptionRequired(
        reason: SubscriptionBlockReason.inactive,
        canManagePlans: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('Suscripción inactiva'), findsOneWidget);
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      expect(find.text('planes'), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('Employee: sin "Ver planes" y con aviso al dueño',
        (tester) async {
      await _pumpApp(tester);
      AppDialogs.subscriptionRequired(canManagePlans: false, message: 'Límite');
      await tester.pumpAndSettle();
      expect(find.text('Límite'), findsOneWidget);
      expect(find.text('Ver planes disponibles'), findsNothing);
      expect(find.textContaining('administrador'), findsOneWidget);
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.text('planes'), findsNothing);
    });
  });

  testWidgets('AppDialogTitle: ícono con degradado, título y subtítulo',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeConfig.lightTheme,
      home: const Scaffold(
        body: AppDialogTitle(
          icon: Icons.payments_rounded,
          title: 'Registrar pago',
          subtitle: 'Carla Díaz',
          trailing: Icon(Icons.close_rounded),
        ),
      ),
    ));
    expect(find.text('Registrar pago'), findsOneWidget);
    expect(find.text('Carla Díaz'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    final circle = tester.widget<Container>(find
        .ancestor(
            of: find.byIcon(Icons.payments_rounded),
            matching: find.byType(Container))
        .first);
    final context = tester.element(find.text('Registrar pago'));
    expect((circle.decoration! as BoxDecoration).gradient,
        context.tokens.primaryGradient);
  });
}
