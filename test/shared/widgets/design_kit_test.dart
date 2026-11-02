import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/enums/appointment_payment_status_enum.dart';
import 'package:login_signup/common/enums/appointment_status_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/core/widgets/app_pressable.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';
import 'package:login_signup/shared/widgets/app_sheet.dart';
import 'package:login_signup/shared/widgets/money_field.dart';
import 'package:login_signup/shared/widgets/palette_swatch.dart';
import 'package:login_signup/shared/widgets/status_chip.dart';

/// Kit del sistema de diseño (12.03): sin lógica de negocio, colores de los
/// tokens.
void main() {
  Future<void> pump(WidgetTester tester, Widget child,
      {ThemeData? theme}) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme ?? ThemeConfig.lightTheme,
      home: Scaffold(body: Center(child: child)),
    ));
  }

  group('AppGradientButton', () {
    testWidgets('degradado de la paleta, sombra teñida y FilledButton dentro',
        (tester) async {
      var taps = 0;
      await pump(
          tester,
          AppGradientButton(
              label: 'Guardar',
              icon: Icons.save_rounded,
              onPressed: () => taps++));
      expect(find.widgetWithText(FilledButton, 'Guardar'), findsOneWidget);
      final box = tester.widget<AnimatedContainer>(find.descendant(
          of: find.byType(AppGradientButton),
          matching: find.byType(AnimatedContainer)));
      final decoration = box.decoration! as BoxDecoration;
      final tokens = ThemeConfig.lightTheme.extension<AppTokens>()!;
      expect(decoration.gradient, tokens.primaryGradient);
      expect(decoration.boxShadow, hasLength(2));

      await tester.tap(find.text('Guardar'));
      expect(taps, 1);
    });

    testWidgets('se encoge al pulsar y vuelve al soltar', (tester) async {
      await pump(tester, AppGradientButton(label: 'Ok', onPressed: () {}));
      double scale() => tester
          .widget<AnimatedScale>(find.descendant(
              of: find.byType(AppPressable),
              matching: find.byType(AnimatedScale)))
          .scale;
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Ok')));
      await tester.pump();
      expect(scale(), AppMotion.pressedScale);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(scale(), 1);
    });

    testWidgets('cargando: ruedita dentro, texto visible y no se pulsa',
        (tester) async {
      var taps = 0;
      await pump(
          tester,
          AppGradientButton(
              label: 'Guardar', loading: true, onPressed: () => taps++));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      await tester.tap(find.text('Guardar'));
      expect(taps, 0);
    });

    testWidgets('sin onPressed: deshabilitado y sin degradado', (tester) async {
      await pump(
          tester, const AppGradientButton(label: 'Nada', onPressed: null));
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      final box = tester.widget<AnimatedContainer>(find.descendant(
          of: find.byType(AppGradientButton),
          matching: find.byType(AnimatedContainer)));
      expect((box.decoration! as BoxDecoration).gradient, isNull);
    });

    testWidgets('FAB extendido con tooltip', (tester) async {
      await pump(
          tester,
          AppGradientButton.fab(
              label: 'Cita', tooltip: 'Nueva cita', onPressed: () {}));
      expect(find.byTooltip('Nueva cita'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });
  });

  group('AppCard', () {
    testWidgets('es un Card con dos capas de sombra y se puede pulsar',
        (tester) async {
      var taps = 0;
      await pump(
          tester,
          AppCard(
              tint: const Color(0xFF10B981),
              onTap: () => taps++,
              child: const Text('Cita')));
      expect(find.ancestor(of: find.text('Cita'), matching: find.byType(Card)),
          findsOneWidget);
      final shadow = tester
          .widgetList<DecoratedBox>(find.descendant(
              of: find.byType(AppCard), matching: find.byType(DecoratedBox)))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.boxShadow != null);
      expect(shadow.boxShadow, hasLength(2));
      expect(shadow.boxShadow![1].color.withValues(alpha: 1),
          const Color(0xFF10B981));
      await tester.tap(find.text('Cita'));
      expect(taps, 1);
    });

    testWidgets('profundidad 0: sin sombra', (tester) async {
      await pump(tester, const AppCard(depth: 0, child: Text('Plana')));
      final decorations = tester
          .widgetList<DecoratedBox>(find.descendant(
              of: find.byType(AppCard), matching: find.byType(DecoratedBox)))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>();
      expect(
          decorations.every((d) => d.boxShadow == null || d.boxShadow!.isEmpty),
          isTrue);
    });
  });

  testWidgets('AppSectionHeader: título, subtítulo y acción', (tester) async {
    var taps = 0;
    await pump(
        tester,
        AppSectionHeader(
            title: 'Hoy',
            subtitle: '3 citas',
            icon: Icons.today_rounded,
            actionLabel: 'Ver todo',
            onAction: () => taps++));
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('3 citas'), findsOneWidget);
    await tester.tap(find.text('Ver todo'));
    expect(taps, 1);
  });

  group('StatusChip', () {
    testWidgets('estados de cita y pago de la guía, con ícono y tono',
        (tester) async {
      await pump(
          tester,
          Wrap(children: [
            for (final s in AppointmentStatus.values) StatusChip.appointment(s),
            StatusChip.payment(AppointmentPaymentStatus.PARTIAL),
            StatusChip.payment(AppointmentPaymentStatus.COMPLETED),
            StatusChip.toReschedule(),
          ]));
      for (final label in [
        'Pendiente',
        'Confirmada',
        'Completada',
        'Cancelada',
        'Anticipo',
        'Pagada',
        'Por mover',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      final tokens = ThemeConfig.lightTheme.extension<AppTokens>()!;
      final confirmed = tester.widget<Text>(find.text('Confirmada'));
      expect(confirmed.style?.color, tokens.statusConfirmed.onContainer);
      expect(find.bySemanticsLabel('Estado: Pagada'), findsOneWidget);
    });

    test('los textos coinciden con los de la cita (una sola fuente)', () {
      expect(
          StatusChip.appointmentLabel(AppointmentStatus.PENDING), 'Pendiente');
      expect(StatusChip.paymentLabel(AppointmentPaymentStatus.PENDING),
          'Sin pagar');
      expect(StatusChip.paymentTone(AppointmentPaymentStatus.COMPLETED),
          AppTone.success);
    });
  });

  group('AppAvatar', () {
    test('iniciales', () {
      expect(AppAvatar.initialsOf('Ana María Pérez'), 'AP');
      expect(AppAvatar.initialsOf('  laura '), 'L');
      expect(AppAvatar.initialsOf(''), '?');
    });

    testWidgets('iniciales sobre el degradado; apagado sin degradado',
        (tester) async {
      await pump(tester, const AppAvatar(name: 'Laura Ruiz'));
      expect(find.text('LR'), findsOneWidget);
      BoxDecoration decoration() => tester
          .widget<Container>(find.descendant(
              of: find.byType(AppAvatar), matching: find.byType(Container)))
          .decoration! as BoxDecoration;
      expect(decoration().gradient, isNotNull);

      await pump(tester, const AppAvatar(name: 'Laura Ruiz', muted: true));
      expect(decoration().gradient, isNull);
    });
  });

  testWidgets('AppSheet: título con ícono, contenido y botones al pie',
      (tester) async {
    String? result;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeConfig.lightTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await AppSheet.show<String>(
                context,
                title: 'Filtrar',
                icon: Icons.tune_rounded,
                builder: (_) => const Text('Contenido'),
                actions: (context) => [
                  OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.of(context).pop('ok'),
                      child: const Text('Aplicar')),
                ],
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Filtrar'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.text('Contenido'), findsOneWidget);
    // Asa del tema (radio 28 en BottomSheetTheme).
    expect(ThemeConfig.lightTheme.bottomSheetTheme.showDragHandle, isTrue);
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    expect(result, 'ok');
  });

  group('MoneyField', () {
    testWidgets('separador de miles en vivo y valor int', (tester) async {
      final values = <int?>[];
      await pump(
          tester,
          SizedBox(
              width: 300,
              child: MoneyField(label: 'Precio', onChanged: values.add)));
      expect(find.text(r'$ '), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '15000');
      await tester.pump();
      expect(find.text('15.000'), findsOneWidget);
      expect(values.last, 15000);

      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();
      expect(values.last, isNull);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.number);
    });

    testWidgets('con controller externo y valor inicial; tope', (tester) async {
      final controller = TextEditingController(text: MoneyField.textFor(45000));
      addTearDown(controller.dispose);
      await pump(
          tester,
          SizedBox(
              width: 300,
              child: MoneyField(controller: controller, max: 100000)));
      expect(find.text('45.000'), findsOneWidget);
      expect(MoneyField.valueOf(controller), 45000);
      await tester.enterText(find.byType(TextFormField), '250000');
      await tester.pump();
      // Supera el tope: se queda el valor anterior.
      expect(MoneyField.valueOf(controller), 45000);
    });

    testWidgets('el validador recibe el monto', (tester) async {
      final formKey = GlobalKey<FormState>();
      await pump(
          tester,
          Form(
            key: formKey,
            child: SizedBox(
              width: 300,
              child: MoneyField(
                initialValue: 0,
                validator: (amount) =>
                    (amount ?? 0) <= 0 ? 'Escribe un monto' : null,
              ),
            ),
          ));
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Escribe un monto'), findsOneWidget);
    });
  });

  testWidgets('PaletteSwatchGrid: 6 muestras, la elegida marcada',
      (tester) async {
    AppPalette? tapped;
    await pump(
        tester,
        SizedBox(
          width: 400,
          child: PaletteSwatchGrid(
              selected: AppPalette.rosa, onSelected: (p) => tapped = p),
        ));
    expect(find.byType(PaletteSwatch), findsNWidgets(6));
    expect(
        tester
            .widget<PaletteSwatch>(find.ancestor(
                of: find.byKey(const Key('palette-rosa')),
                matching: find.byType(PaletteSwatch)))
            .selected,
        isTrue);
    await tester.tap(find.byKey(const Key('palette-grafito')));
    expect(tapped, AppPalette.grafito);
  });

  testWidgets('en oscuro y alto contraste también se pintan', (tester) async {
    for (final variant in AppThemeVariant.values) {
      await pump(
          tester,
          Column(mainAxisSize: MainAxisSize.min, children: [
            AppGradientButton(label: 'Ok', onPressed: () {}),
            const AppCard(child: Text('Tarjeta')),
            StatusChip.appointment(AppointmentStatus.PENDING),
          ]),
          theme: ThemeConfig.of(AppPalette.grafito, variant));
      expect(tester.takeException(), isNull);
    }
  });
}
