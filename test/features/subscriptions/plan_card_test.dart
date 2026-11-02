import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/features/subscriptions/presentation/widgets/plan_card.dart';

/// Tarjetas de plan (12.05): el plan destacado es el de menor precio por mes.
void main() {
  SubscriptionPlanEntity plan(String id, double price, int months,
          {String currency = 'COP'}) =>
      SubscriptionPlanEntity(
          id: id,
          name: 'Plan $id',
          price: price,
          currency: currency,
          durationMonths: months,
          appointmentLimit: -1);

  group('bestValuePlanId', () {
    test('el de menor precio por mes', () {
      expect(
          bestValuePlanId([
            plan('m', 50000, 1),
            plan('s', 270000, 6),
            plan('a', 480000, 12),
          ]),
          'a');
    });

    test('un solo plan, empate, monedas distintas o gratis: ninguno', () {
      expect(bestValuePlanId([plan('m', 50000, 1)]), isNull);
      expect(
          bestValuePlanId([plan('m', 50000, 1), plan('s', 300000, 6)]), isNull);
      expect(
          bestValuePlanId([
            plan('m', 50000, 1),
            plan('u', 100, 12, currency: 'USD'),
          ]),
          isNull);
      expect(bestValuePlanId([plan('g', 0, 1), plan('m', 50000, 1)]), isNull);
    });

    test('precio por mes', () {
      expect(planMonthlyPrice(plan('s', 270000, 6)), 45000);
      expect(planMonthlyPrice(plan('x', 1000, 0)), isNull);
    });
  });

  Future<void> pump(WidgetTester tester, Widget card,
      {ThemeData? theme, bool settle = true}) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: theme ?? ThemeConfig.lightTheme,
      home: Scaffold(
          body: SingleChildScrollView(
              padding: const EdgeInsets.all(24), child: card)),
    ));
    // La ruedita de carga nunca "se asienta".
    settle
        ? await tester.pumpAndSettle()
        : await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('destacado: cinta, botón con degradado y equivalente mensual',
      (tester) async {
    var taps = 0;
    await pump(
        tester,
        PlanCard(
            plan: plan('a', 480000, 12),
            highlighted: true,
            onSelect: () => taps++));
    expect(find.text('Mejor precio por mes'), findsOneWidget);
    expect(find.byType(AppGradientButton), findsOneWidget);
    expect(find.textContaining('al mes'), findsOneWidget);
    expect(find.textContaining('/ año'), findsOneWidget);
    await tester.tap(find.text('Elegir plan'));
    expect(taps, 1);
  });

  testWidgets('normal: sin cinta, botón tonal; plan actual con píldora',
      (tester) async {
    await pump(
        tester,
        PlanCard(
            plan: plan('m', 50000, 1), isCurrent: true, onSelect: () {}));
    expect(find.text('Mejor precio por mes'), findsNothing);
    expect(find.byType(AppGradientButton), findsNothing);
    expect(find.text('Plan actual'), findsOneWidget);
    expect(find.text('Renovar plan'), findsOneWidget);
    // Mensual: no hace falta el equivalente.
    expect(find.textContaining('al mes'), findsNothing);
  });

  testWidgets('pidiendo el enlace: carga dentro del botón', (tester) async {
    await pump(
        tester,
        PlanCard(
            plan: plan('a', 480000, 12), highlighted: true, isStarting: true),
        theme: ThemeConfig.darkTheme,
        settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
