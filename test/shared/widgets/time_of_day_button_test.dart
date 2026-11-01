import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/shared/widgets/time_of_day_button.dart';

/// 7.05b: el selector de hora de la app es de 24 h aunque el dispositivo (o
/// `main.dart`) esté en 12 h. Antes, escribir "19" en el modo de texto daba
/// "Indica una hora válida".
void main() {
  Future<void> pumpButton(WidgetTester tester, ValueChanged<String> onPicked,
      {String value = '09:00'}) async {
    // El dispositivo en 12 h.
    tester.platformDispatcher.alwaysUse24HourFormatTestValue = false;
    addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      // Como `main.dart`: 12 h para toda la app.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
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

  Future<void> typeTime(WidgetTester tester, String hour, String minute) async {
    await tester.tap(find.text('Abre: 09:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.descendant(
        of: find.byType(TimePickerDialog), matching: find.byType(TextField));
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), hour);
    await tester.enterText(fields.at(1), minute);
    await tester.pump();
  }

  Future<void> accept(WidgetTester tester) async {
    final dialog = find.byType(TimePickerDialog);
    final ok = MaterialLocalizations.of(tester.element(dialog)).okButtonLabel;
    await tester.tap(find.descendant(of: dialog, matching: find.text(ok)));
    await tester.pumpAndSettle();
  }

  testWidgets('dispositivo en 12 h: escribir 19:00 devuelve 19:00',
      (tester) async {
    String? picked;
    await pumpButton(tester, (v) => picked = v);
    await typeTime(tester, '19', '00');
    await accept(tester);

    expect(find.text('Indica una hora válida'), findsNothing);
    expect(find.byType(TimePickerDialog), findsNothing);
    expect(picked, '19:00');
  });

  testWidgets('medianoche y madrugada también en 24 h', (tester) async {
    String? picked;
    await pumpButton(tester, (v) => picked = v);
    await typeTime(tester, '0', '30');
    await accept(tester);
    expect(picked, '00:30');
  });

  testWidgets('el selector se pinta en 24 h (sin AM/PM)', (tester) async {
    await pumpButton(tester, (_) {});
    await tester.tap(find.text('Abre: 09:00'));
    await tester.pumpAndSettle();
    final dialog = find.byType(TimePickerDialog);
    expect(MediaQuery.alwaysUse24HourFormatOf(tester.element(dialog)), isTrue);
    final localizations = MaterialLocalizations.of(tester.element(dialog));
    expect(
        find.descendant(
            of: dialog,
            matching: find.text(localizations.anteMeridiemAbbreviation)),
        findsNothing);
  });
}
