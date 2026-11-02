import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/shared/widgets/app_time_picker.dart';
import 'package:login_signup/shared/widgets/time_of_day_button.dart';

/// D-23 (revisa 7.05b): la hora se ve y se elige en 12 h con a. m./p. m., sea
/// cual sea el ajuste del dispositivo, con la hoja de ruedas `AppTimePicker`
/// (ya no el `showTimePicker` de Material). El valor sigue en `HH:mm`.
void main() {
  Future<void> pumpButton(WidgetTester tester, ValueChanged<String> onPicked,
      {String value = '09:00', bool device24h = false}) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.alwaysUse24HourFormatTestValue = device24h;
    addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeConfig.lightTheme,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Scaffold(
        body: Center(
          child: TimeOfDayButton(
            label: 'Abre',
            value: value,
            semantics: 'Hora de apertura',
            onPicked: onPicked,
          ),
        ),
      ),
    ));
  }

  FixedExtentScrollController wheel(WidgetTester tester, Key key) => tester
      .widget<ListWheelScrollView>(find.descendant(
          of: find.byKey(key), matching: find.byType(ListWheelScrollView)))
      .controller! as FixedExtentScrollController;

  /// Elige en las ruedas (índices: hora 1–12 → 0–11; minutos de 5 en 5;
  /// a. m. = 0, p. m. = 1) y pulsa "Listo".
  Future<void> pick(WidgetTester tester,
      {required int hour12, required int minute, required bool pm}) async {
    wheel(tester, AppTimePicker.hourWheelKey).jumpToItem(hour12 - 1);
    wheel(tester, AppTimePicker.minuteWheelKey).jumpToItem(minute ~/ 5);
    wheel(tester, AppTimePicker.periodWheelKey).jumpToItem(pm ? 1 : 0);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppTimePicker.doneKey));
    await tester.pumpAndSettle();
  }

  testWidgets('el botón muestra la hora en 12 h', (tester) async {
    await pumpButton(tester, (_) {}, value: '19:00');
    expect(find.text('Abre: 7:00 p. m.'), findsOneWidget);
  });

  testWidgets('abre la hoja de ruedas (no el selector de Material)',
      (tester) async {
    await pumpButton(tester, (_) {}, device24h: true);
    await tester.tap(find.text('Abre: 9:00 a. m.'));
    await tester.pumpAndSettle();

    expect(find.byType(AppTimePicker), findsOneWidget);
    expect(find.byType(TimePickerDialog), findsNothing);
    expect(find.text('Hora de apertura'), findsOneWidget);
    // Vista previa grande en 12 h aunque el dispositivo esté en 24 h.
    expect(
        tester.widget<Text>(find.byKey(const Key('time-picker-preview'))).data,
        '9:00 a. m.');
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Listo'), findsOneWidget);
  });

  testWidgets('7:30 p. m. devuelve 19:30', (tester) async {
    String? picked;
    await pumpButton(tester, (v) => picked = v);
    await tester.tap(find.text('Abre: 9:00 a. m.'));
    await tester.pumpAndSettle();
    await pick(tester, hour12: 7, minute: 30, pm: true);

    expect(find.byType(AppTimePicker), findsNothing);
    expect(picked, '19:30');
  });

  testWidgets('12:05 a. m. es medianoche y 12:00 p. m. el mediodía',
      (tester) async {
    String? picked;
    await pumpButton(tester, (v) => picked = v);
    await tester.tap(find.text('Abre: 9:00 a. m.'));
    await tester.pumpAndSettle();
    await pick(tester, hour12: 12, minute: 5, pm: false);
    expect(picked, '00:05');

    await tester.tap(find.text('Abre: 9:00 a. m.'));
    await tester.pumpAndSettle();
    await pick(tester, hour12: 12, minute: 0, pm: true);
    expect(picked, '12:00');
  });

  testWidgets('la vista previa sigue a las ruedas; Cancelar no cambia nada',
      (tester) async {
    String? picked;
    await pumpButton(tester, (v) => picked = v);
    await tester.tap(find.text('Abre: 9:00 a. m.'));
    await tester.pumpAndSettle();
    wheel(tester, AppTimePicker.periodWheelKey).jumpToItem(1);
    await tester.pumpAndSettle();
    expect(
        tester.widget<Text>(find.byKey(const Key('time-picker-preview'))).data,
        '9:00 p. m.');

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(AppTimePicker), findsNothing);
    expect(picked, isNull);
  });

  test('minutos: paso configurable y el minuto inicial fuera del paso', () {
    expect(AppTimePicker.minuteValues(5, 0), hasLength(12));
    expect(AppTimePicker.minuteValues(15, 7), [0, 7, 15, 30, 45]);
    expect(AppTimePicker.hour12Of(const TimeOfDay(hour: 0, minute: 0)), 12);
    expect(AppTimePicker.hour12Of(const TimeOfDay(hour: 13, minute: 0)), 1);
    expect(AppTimePicker.compose(12, 0, pm: false),
        const TimeOfDay(hour: 0, minute: 0));
    expect(AppTimePicker.compose(11, 59, pm: true),
        const TimeOfDay(hour: 23, minute: 59));
  });
}
