// Utilidades comunes de las pruebas de integración en macOS (7.02 y 7.05):
// arrancar la app con vista de teléfono, anotar comprobaciones, capturas,
// esperar sin `pumpAndSettle`, escribir, tocar, menú, login y logout, y los
// selectores de la app (hora, duración, código de 6 dígitos).
//
// Las capturas se guardan en el `tmp` del contenedor de la app (sandbox de
// macOS): `~/Library/Containers/<bundle>/Data/tmp/shots/NN_paso.png`.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/main.dart' as app;

/// Contraseña de todas las cuentas de prueba (cumple la política: el `#` no
/// está entre los especiales permitidos).
const testPassword = 'Clave@2026a';

final _checks = <String>[];
final _failures = <String>[];
var _shotIndex = 0;

void log(String message) {
  // ignore: avoid_print
  print(message);
}

/// Anota una comprobación PASS/FAIL (la prueba sigue; al final, [finish]).
void check(bool ok, String name, [Object? info]) {
  final line =
      '${ok ? 'PASS' : 'FAIL'}  $name${info == null ? '' : '  -> $info'}';
  _checks.add(line);
  if (!ok) _failures.add(line);
  log(line);
}

/// Paso que no se pudo probar por una condición externa (no es un fallo).
void skip(String name, String reason) {
  final line = 'SKIP  $name  -> $reason';
  _checks.add(line);
  log(line);
}

int get passCount => _checks.where((c) => c.startsWith('PASS')).length;
int get failCount => _failures.length;

/// Captura la vista raíz (sin `takeScreenshot`, que no existe en desktop).
Future<void> shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 300));
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final ratio = view.flutterView.devicePixelRatio;
  final file = '${(_shotIndex++).toString().padLeft(3, '0')}_$name.png';
  await tester.runAsync(() async {
    final dir = Directory('${Directory.systemTemp.path}/shots')
      ..createSync(recursive: true);
    final image = await layer.toImage(view.paintBounds, pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('${dir.path}/$file').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  log('SHOT $file');
}

/// Textos visibles (para el informe y para comprobar contenidos).
List<String> texts() => find
    .byType(Text)
    .evaluate()
    .map((e) {
      final w = e.widget as Text;
      return w.data ?? w.textSpan?.toPlainText() ?? '';
    })
    .where((s) => s.trim().isNotEmpty)
    .toList();

String allText() => texts().join(' | ');

/// Textos de toda la lista visible, recorriéndola hacia abajo (las listas
/// perezosas solo construyen lo que se ve). Vuelve arriba al terminar.
Future<String> scrollTexts(WidgetTester tester) async {
  final seen = <String>{...texts()};
  final list = find.byType(Scrollable).first;
  for (var i = 0; i < 12; i++) {
    await tester.drag(list, const Offset(0, -500), warnIfMissed: false);
    await idle(tester, 400);
    seen.addAll(texts());
  }
  for (var i = 0; i < 12; i++) {
    await tester.drag(list, const Offset(0, 500), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
  }
  await idle(tester, 600);
  return seen.join(' | ');
}

void dump(String label) => log('[$label] ${allText()}');

/// Bombea frames hasta que aparezca [finder] (sin `pumpAndSettle`, que no
/// termina con indicadores de progreso o el calendario animado).
Future<bool> waitFor(WidgetTester tester, Finder finder,
    {Duration timeout = const Duration(seconds: 15)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

/// Como [waitFor], pero hasta que [finder] desaparezca.
Future<bool> waitGone(WidgetTester tester, Finder finder,
    {Duration timeout = const Duration(seconds: 15)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isEmpty) return true;
  }
  return false;
}

Future<void> idle(WidgetTester tester, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tap(WidgetTester tester, Finder finder, {int wait = 800}) async {
  await centerOn(tester, finder.first);
  await tester.tap(finder.first, warnIfMissed: false);
  await idle(tester, wait);
}

/// Lleva [finder] al centro de su lista (con `ensureVisible` normal queda
/// pegado al borde y a veces debajo de otra capa).
Future<void> centerOn(WidgetTester tester, Finder finder) async {
  final context = tester.element(finder);
  if (Scrollable.maybeOf(context) != null) {
    await tester.runAsync(() => Scrollable.ensureVisible(context,
        alignment: 0.5, duration: Duration.zero));
  }
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> tapText(WidgetTester tester, String text, {int wait = 800}) async {
  final finder = find.text(text);
  if (!await waitFor(tester, finder)) {
    throw StateError('No aparece "$text". Pantalla: ${allText()}');
  }
  await tap(tester, finder.last, wait: wait);
}

Finder field(String label) => find.byWidgetPredicate((w) =>
    w is TextField &&
    (w.decoration?.labelText == label || w.decoration?.hintText == label));

Future<void> type(WidgetTester tester, String label, String value) async {
  final f = field(label);
  if (!await waitFor(tester, f)) {
    throw StateError('No hay campo "$label". Pantalla: ${allText()}');
  }
  await tester.ensureVisible(f.first);
  await tester.enterText(f.first, value);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> openDrawerItem(WidgetTester tester, String item) async {
  await tap(tester, find.byType(DrawerButton));
  await tapText(tester, item, wait: 1500);
}

Future<void> back(WidgetTester tester) async {
  final button = find.byType(BackButton);
  if (button.evaluate().isNotEmpty) {
    await tap(tester, button.last, wait: 1200);
  } else {
    Get.back();
    await idle(tester, 1200);
  }
}

/// El backend limita por IP el login, el registro y los códigos (5-10 por
/// minuto, compartidos con otras pruebas): ante "Demasiados intentos" se
/// espera un minuto y se reintenta.
bool get isThrottled => allText().contains('Demasiados intentos');

Future<void> waitThrottle(WidgetTester tester, String what) async {
  log('429 en $what: espera de 61 s');
  await idle(tester, 61000);
}

Future<void> login(WidgetTester tester, String email,
    {String password = testPassword, bool expectHome = true}) async {
  await waitFor(tester, find.text('Iniciar sesión'),
      timeout: const Duration(seconds: 30));
  for (var attempt = 0; attempt < 3; attempt++) {
    await type(tester, 'Correo electrónico', email);
    await type(tester, 'Contraseña', password);
    await tapText(tester, 'Iniciar sesión', wait: 300);
    final ok = await waitFor(tester, find.byTooltip('Nueva cita'),
        timeout: const Duration(seconds: 20));
    if (ok || !expectHome) {
      if (expectHome) check(ok, 'login $email llega a la agenda');
      await idle(tester, 2500);
      return;
    }
    if (!isThrottled) {
      check(false, 'login $email llega a la agenda', allText());
      return;
    }
    await dismissDialogs(tester);
    await waitThrottle(tester, 'login');
  }
  check(false, 'login $email llega a la agenda (429 persistente)');
}

/// Cierra un diálogo informativo abierto (Aceptar/Entendido/Cerrar).
Future<void> dismissDialogs(WidgetTester tester) async {
  for (final label in const ['Entendido', 'Aceptar', 'ACEPTAR', 'Cerrar']) {
    final f =
        find.descendant(of: find.byType(Dialog), matching: find.text(label));
    if (f.evaluate().isNotEmpty) {
      await tap(tester, f.last, wait: 600);
      return;
    }
  }
}

Future<void> logout(WidgetTester tester) async {
  await openDrawerItem(tester, 'Cerrar sesión');
  await shot(tester, 'confirmar_cierre');
  // Botón del diálogo de confirmación.
  await tap(tester, find.widgetWithText(FilledButton, 'Cerrar sesión'),
      wait: 300);
  final ok = await waitFor(tester, find.text('¡Bienvenido de vuelta!'),
      timeout: const Duration(seconds: 15));
  check(ok, 'cerrar sesión vuelve al login');
  await idle(tester, 1500);
}

/// Va a la vista de día de [day] (por el controlador: las flechas del
/// SfCalendar no tienen semántica para buscarlas de forma estable).
Future<void> showDay(WidgetTester tester, DateTime day) async {
  await Get.find<AppointmentsController>().showDay(day);
  await idle(tester, 2500);
}

Finder tileOf(String client) => find.text(client);

/// Abre el detalle de la cita de [client] en el día visible.
Future<bool> openDetail(WidgetTester tester, String client) async {
  final f = tileOf(client);
  if (!await waitFor(tester, f, timeout: const Duration(seconds: 8))) {
    return false;
  }
  await tap(tester, f, wait: 1500);
  return waitFor(tester, find.byTooltip('Cerrar'));
}

Future<void> closeDialog(WidgetTester tester) async {
  await tap(tester, find.byTooltip('Cerrar'), wait: 800);
}

/// Elige [hhmm] en el selector de hora de Material que abre [button]: pasa
/// al modo de texto (el reloj no se puede tocar de forma estable) y escribe
/// hora y minutos en 24 h: la app fuerza ese formato en el selector
/// (`showAppTimePicker`, 7.05b), sea cual sea el ajuste del dispositivo.
Future<void> pickTime(WidgetTester tester, Finder button, String hhmm) async {
  final label = find.descendant(of: button, matching: find.byType(Text));
  await centerOn(tester, label.first);
  await tester.tap(label.first);
  await idle(tester, 800);
  final toKeyboard = find.byIcon(Icons.keyboard_outlined);
  if (await waitFor(tester, toKeyboard, timeout: const Duration(seconds: 3))) {
    await tap(tester, toKeyboard, wait: 600);
  }
  final fields = find.descendant(
      of: find.byType(TimePickerDialog), matching: find.byType(TextField));
  if (!await waitFor(tester, fields, timeout: const Duration(seconds: 5))) {
    await shot(tester, 'selector_hora_sin_campos');
    throw StateError('Selector de hora sin campos de texto: ${allText()}');
  }
  final parts = hhmm.split(':');
  await tester.enterText(fields.at(0), parts[0]);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.enterText(fields.at(1), parts[1]);
  await tester.pump(const Duration(milliseconds: 200));
  if (debugPickTime) await shot(tester, 'debug_hora_$hhmm');
  await tapText(tester, 'ACEPTAR', wait: 600);
}

/// Captura de cada selector de hora (diagnóstico).
bool debugPickTime = const bool.fromEnvironment('DEBUG_TIME');

/// Minutos de un texto `1 h 5 min`, `2 h` o `45 min`.
int minutesOf(String text) {
  final h = RegExp(r'(\d+)\s*h').firstMatch(text);
  final m = RegExp(r'(\d+)\s*min').firstMatch(text);
  return (h == null ? 0 : int.parse(h.group(1)!) * 60) +
      (m == null ? 0 : int.parse(m.group(1)!));
}

/// Elige [minutes] en la rueda de duración (de 5 en 5) que ya está abierta y
/// pulsa "Aceptar". `true` si la rueda quedó en ese valor.
Future<bool> pickDuration(WidgetTester tester, int minutes) async {
  final wheel = find.byType(ListWheelScrollView);
  if (!await waitFor(tester, wheel)) return false;
  int selected() {
    final bold = find
        .descendant(of: wheel, matching: find.byType(Text))
        .evaluate()
        .map((e) => e.widget as Text)
        .where((t) => t.style?.fontWeight == FontWeight.bold);
    return bold.isEmpty ? -1 : minutesOf(bold.first.data ?? '');
  }

  for (var i = 0; i < 40; i++) {
    final current = selected();
    if (current == minutes) break;
    if (current < 0) return false;
    final steps = ((minutes - current) / 5).round().clamp(-3, 3);
    await tester.drag(wheel, Offset(0, -50.0 * steps));
    await idle(tester, 700);
  }
  final ok = selected() == minutes;
  await tapText(tester, 'Aceptar');
  return ok;
}

/// Escribe el código de 6 dígitos en el `PinCodeTextField` visible.
Future<void> enterPin(WidgetTester tester, String code) async {
  final input = find.descendant(
      of: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'PinCodeTextField'),
      matching: find.byType(TextField));
  await waitFor(tester, input);
  await tester.enterText(input.first, code);
  await idle(tester, 800);
}

/// Arranca la app con vista de teléfono (430 x 932 lógicos), almacenamiento
/// seguro en memoria (el keychain de macOS da -34018 sin entitlement) y los
/// overflow anotados como hallazgo. Devuelve la función que restaura el
/// manejador de errores.
Future<void Function()> startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(860, 1864);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  FlutterSecureStorage.setMockInitialValues({});
  app.main();
  final originalOnError = FlutterError.onError;
  final overflows = <String>{};
  FlutterError.onError = (details) {
    final text = details.exceptionAsString();
    if (text.contains('overflowed')) {
      if (overflows.add(text)) check(false, 'overflow en pantalla', text);
      return;
    }
    if (text.contains('deactivated widget')) return; // eco del overflow
    originalOnError?.call(details);
  };
  await idle(tester, 4000);
  return () => FlutterError.onError = originalOnError;
}

/// Resumen y veredicto de la prueba.
void finish() {
  log('==== RESUMEN ($passCount PASS, $failCount FAIL) ====');
  for (final c in _checks) {
    log(c);
  }
  expect(_failures, isEmpty, reason: _failures.join('\n'));
}
