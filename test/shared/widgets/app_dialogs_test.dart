import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
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
}
