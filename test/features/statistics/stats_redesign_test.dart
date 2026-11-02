import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_method_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_stats_entity.dart';
import 'package:login_signup/features/statistics/presentation/widgets/overview_stats_card.dart';
import 'package:login_signup/features/statistics/presentation/widgets/payment_methods_chart.dart';
import 'package:login_signup/features/statistics/presentation/widgets/stats_card.dart';

/// 12.07: KPI con montos formateados y cifras tabulares; gráfica con los
/// colores del tema (sin colores fijos) y el ícono de cada método.
void main() {
  Future<void> pump(WidgetTester tester, Widget child,
      {ThemeData? theme}) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme ?? ThemeConfig.lightTheme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ));
    await tester.pumpAndSettle();
  }

  bool isTabular(WidgetTester tester, String text) {
    final style = tester.widget<Text>(find.text(text)).style;
    return style?.fontFeatures?.contains(const FontFeature.tabularFigures()) ??
        false;
  }

  testWidgets('KPI del resumen: montos con separador de miles y tabulares',
      (tester) async {
    await pump(
        tester,
        const OverviewStatsCard(
          stats: PaymentStatsEntity(
              totalAmount: 1234567, paymentCount: 12, averageAmount: 102880.5),
        ));

    expect(find.text('Ingresos netos'), findsOneWidget);
    expect(find.text('\$ 1.234.567'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    // formatCop redondea a pesos.
    expect(find.text('\$ 102.881'), findsOneWidget);
    expect(isTabular(tester, '\$ 1.234.567'), isTrue);
    expect(isTabular(tester, '\$ 102.881'), isTrue);
    expect(find.byType(StatTile), findsNWidgets(2));
    expect(find.byType(StatHero), findsOneWidget);
  });

  testWidgets('la cifra principal usa el degradado de la paleta',
      (tester) async {
    await pump(
        tester,
        const StatHero(
            label: 'Ingresos netos',
            value: '\$ 10.000',
            icon: Icons.payments_rounded));
    final box = tester.widget<Container>(find
        .ancestor(of: find.text('\$ 10.000'), matching: find.byType(Container))
        .last);
    final decoration = box.decoration! as BoxDecoration;
    final context = tester.element(find.text('\$ 10.000'));
    expect(decoration.gradient, context.tokens.primaryGradient);
  });

  testWidgets('gráfica de métodos: colores del tema e ícono del método',
      (tester) async {
    const stats = [
      PaymentMethodStatsEntity(
          method: 'CASH',
          paymentMethod: PaymentMethod.CASH,
          total: 30000,
          count: 2,
          average: 15000,
          percentage: 60),
      PaymentMethodStatsEntity(
          method: 'TRANSFER',
          paymentMethod: PaymentMethod.TRANSFER,
          total: 20000,
          count: 1,
          average: 20000,
          percentage: 40),
    ];
    for (final theme in [ThemeConfig.lightTheme, ThemeConfig.darkTheme]) {
      await pump(tester, const PaymentMethodsChart(stats: stats),
          theme: theme);
      final context = tester.element(find.byType(PaymentMethodsChart));
      final colors = PaymentMethodsChart.palette(context);
      expect(colors.first, theme.colorScheme.primary);
      expect(colors, contains(context.tokens.success.color));
      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('\$ 50.000'), findsOneWidget); // total en el centro
      expect(find.byIcon(Icons.payments_rounded), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_rounded), findsOneWidget);
      expect(find.text('60 %'), findsOneWidget);
    }
  });
}
