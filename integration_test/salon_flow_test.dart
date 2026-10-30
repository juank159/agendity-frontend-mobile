// Prueba 7.02: el salón de cejas y pestañas recorrido desde la app real
// (macOS desktop) contra el backend de demo (`agendity_demo`, 7.01).
//
//   flutter test integration_test/salon_flow_test.dart -d macos
//
// Necesita el backend de demo en `API_URL` con los datos de 7.01 (Owner
// Marcela, empleadas Ana y Laura, citas del 30 y 31 de octubre de 2026).
// Las capturas se guardan en el `tmp` del contenedor de la app (sandbox de
// macOS): `~/Library/Containers/<bundle>/Data/tmp/shots/NN_paso.png`.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/main.dart' as app;

const _password = 'Clave@2026a';
const _owner = 'marcela.rojas@example.com';
const _ana = 'ana.gomez@example.com';

/// Sufijo para que el servicio y el cliente nuevos no choquen entre corridas.
final _run = DateTime.now().millisecondsSinceEpoch.toString().substring(7);

final _checks = <String>[];
final _failures = <String>[];
var _shotIndex = 0;

void _log(String message) {
  // ignore: avoid_print
  print(message);
}

void check(bool ok, String name, [Object? info]) {
  final line =
      '${ok ? 'PASS' : 'FAIL'}  $name${info == null ? '' : '  -> $info'}';
  _checks.add(line);
  if (!ok) _failures.add(line);
  _log(line);
}

/// Captura la vista raíz (sin `takeScreenshot`, que no existe en desktop).
Future<void> shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 300));
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final ratio = view.flutterView.devicePixelRatio;
  final file = '${(_shotIndex++).toString().padLeft(2, '0')}_$name.png';
  await tester.runAsync(() async {
    final dir = Directory('${Directory.systemTemp.path}/shots')
      ..createSync(recursive: true);
    final image = await layer.toImage(view.paintBounds, pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('${dir.path}/$file').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  _log('SHOT $file');
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

void dump(String label) => _log('[$label] ${allText()}');

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

Future<void> idle(WidgetTester tester, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tap(WidgetTester tester, Finder finder, {int wait = 800}) async {
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first, warnIfMissed: false);
  await idle(tester, wait);
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
    await tap(tester, button, wait: 1200);
  } else {
    Get.back();
    await idle(tester, 1200);
  }
}

Future<void> login(WidgetTester tester, String email) async {
  await waitFor(tester, find.text('Iniciar sesión'),
      timeout: const Duration(seconds: 30));
  await type(tester, 'Correo electrónico', email);
  await type(tester, 'Contraseña', _password);
  await tapText(tester, 'Iniciar sesión', wait: 300);
  final ok = await waitFor(tester, find.byTooltip('Nueva cita'),
      timeout: const Duration(seconds: 20));
  check(ok, 'login $email llega a la agenda', ok ? null : allText());
  await idle(tester, 2500);
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('salón de cejas y pestañas (Owner y empleada)', (tester) async {
    // Tamaño de teléfono (430 x 932 lógicos).
    tester.view.physicalSize = const Size(860, 1864);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    // Keychain de macOS sin entitlement (-34018): almacenamiento en memoria.
    FlutterSecureStorage.setMockInitialValues({});
    app.main();
    // Los overflow de la app se anotan como hallazgo (una vez por mensaje) en
    // lugar de cortar la prueba; el resto de errores sigue su curso normal.
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
    await shot(tester, 'login');

    // ───────────────────────── Owner ─────────────────────────
    await login(tester, _owner);
    await shot(tester, 'owner_agenda_hoy');
    dump('agenda hoy');

    // Viernes 30: Valentina (Ana, PPP 14:00) y Camila (Laura, 3 servicios 14:00).
    await showDay(tester, DateTime(2026, 10, 30));
    await shot(tester, 'owner_dia_30');
    dump('día 30');
    check(
        texts().contains('Valentina Castro') &&
            texts().contains('Camila Torres'),
        'Owner ve las dos citas del viernes 30',
        allText());

    if (await openDetail(tester, 'Valentina Castro')) {
      await shot(tester, 'detalle_valentina');
      final t = allText();
      dump('detalle Valentina');
      check(t.contains('2:00') && t.contains('4:00'),
          'Valentina: 2:00 p. m. - 4:00 p. m. (hora de Bogotá)', t);
      check(t.contains('2 h'), 'Valentina: duración 2 h');
      check(t.contains('\$ 150.000'), 'Valentina: total \$ 150.000');
      await closeDialog(tester);
    } else {
      check(false, 'abrir detalle de Valentina', allText());
    }

    if (await openDetail(tester, 'Camila Torres')) {
      await shot(tester, 'detalle_camila');
      final t = allText();
      dump('detalle Camila');
      check(t.contains('2:00') && t.contains('3:05'),
          'Camila: 2:00 p. m. - 3:05 p. m.', t);
      check(t.contains('1 h 5 min'), 'Camila: duración 1 h 5 min');
      check(t.contains('\$ 160.000'), 'Camila: total \$ 160.000');
      await closeDialog(tester);
    } else {
      check(false, 'abrir detalle de Camila', allText());
    }

    // Sábado 31: Isabella (anticipo), Sofía (cejas), Daniela (cancelada) y la
    // cita indebida cancelada de 7.01.
    await showDay(tester, DateTime(2026, 10, 31));
    await shot(tester, 'owner_dia_31');
    dump('día 31');
    if (await openDetail(tester, 'Isabella Rincón')) {
      await shot(tester, 'detalle_isabella_anticipo');
      final t = allText();
      dump('detalle Isabella');
      check(t.contains('9:00') && t.contains('11:30'),
          'Isabella: 9:00 a. m. - 11:30 a. m.', t);
      check(t.contains('Cobrar saldo'),
          'Isabella (anticipo): botón "Cobrar saldo"');
      await closeDialog(tester);
    }

    // ── Servicio nuevo con color ──
    await openDrawerItem(tester, 'Servicios');
    await shot(tester, 'servicios');
    dump('servicios');
    // Duración de axilas (20 min) al editar: el selector va de 15 en 15.
    if (find.text('Depilación de axilas').evaluate().isNotEmpty) {
      await tap(tester, find.text('Depilación de axilas'), wait: 1500);
      await shot(tester, 'editar_axilas');
      dump('editar axilas');
      await back(tester);
    }
    await tap(tester, find.widgetWithText(FloatingActionButton, 'Servicio'),
        wait: 1500);
    final serviceName = 'Lifting de pestañas $_run';
    await type(tester, 'Nombre del servicio', serviceName);
    await type(tester, 'Precio', '90000');
    await tapText(tester, 'Duración');
    // Rueda de 15 en 15: bajar tres posiciones desde la inicial.
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -150));
    await idle(tester, 1200);
    await shot(tester, 'servicio_duracion');
    dump('rueda duración');
    await tapText(tester, 'Aceptar');
    await tapText(tester, 'Categoría');
    await tapText(tester, 'Pestañas');
    final color = find.byKey(const ValueKey('service-color-#009688'));
    if (await waitFor(tester, color, timeout: const Duration(seconds: 3))) {
      await tap(tester, color);
    } else {
      check(false, 'color #009688 en la paleta', allText());
    }
    await shot(tester, 'servicio_formulario');
    dump('formulario servicio');
    await tapText(tester, 'Guardar', wait: 2500);
    await shot(tester, 'servicio_guardado');
    check(await waitFor(tester, find.text(serviceName)),
        'el servicio nuevo aparece en la lista', allText());
    await back(tester);

    // ── Cliente nuevo ──
    await openDrawerItem(tester, 'Clientela');
    await shot(tester, 'clientes');
    dump('clientes');
    await tap(tester, find.byTooltip('Agregar cliente'));
    await tapText(tester, 'Nuevo cliente', wait: 1500);
    const clientName = 'Mariana';
    final clientLast = 'Prueba $_run';
    await type(tester, 'Nombre *', clientName);
    await type(tester, 'Apellido', clientLast);
    await type(tester, 'Teléfono móvil *', '320${_run.padLeft(7, '0')}');
    await type(tester, 'Email', 'mariana.$_run@example.com');
    await shot(tester, 'cliente_formulario');
    await tapText(tester, 'Guardar cliente', wait: 2500);
    await shot(tester, 'cliente_guardado');
    dump('tras guardar cliente');
    check(await waitFor(tester, find.textContaining(clientLast)),
        'el cliente nuevo aparece', allText());
    await back(tester);

    // ── Cita de varios servicios con Laura (sábado 31, 2:00 p. m.) ──
    await showDay(tester, DateTime(2026, 10, 31));
    await tap(tester, find.byTooltip('Nueva cita'), wait: 2500);
    await shot(tester, 'cita_nueva_vacia');
    await tap(tester, find.byKey(const Key('appointment-professional')));
    await shot(tester, 'cita_profesionales');
    dump('profesionales');
    await tapText(tester, 'Laura Pérez');
    await tap(tester, find.byKey(const Key('appointment-services')));
    await shot(tester, 'cita_servicios');
    dump('servicios de la cita');
    for (final s in const [
      'Cejas semipermanente',
      'Depilación de bozo',
      'Depilación de axilas',
    ]) {
      // La casilla del selector (no el texto de un bloque de la agenda).
      final tile = find.widgetWithText(CheckboxListTile, s);
      await waitFor(tester, tile);
      await tap(tester, tile, wait: 500);
      final checked = tile.evaluate().isNotEmpty &&
          (tile.evaluate().first.widget as CheckboxListTile).value == true;
      check(checked, 'servicio marcado: $s');
    }
    await tapText(tester, 'Listo');
    final summary = allText();
    check(summary.contains('\$ 160.000 · 1 h 5 min'),
        'formulario: total \$ 160.000 y duración 1 h 5 min', summary);
    await tap(tester, find.byKey(const Key('appointment-client')));
    await type(tester, 'Buscar por nombre o teléfono', clientLast);
    await idle(tester, 2000);
    await shot(tester, 'cita_buscar_cliente');
    await tapText(tester, '$clientName $clientLast');
    // Día: ya viene el 31 si la agenda está en ese día; si no, el selector.
    if (!allText().toLowerCase().contains('31 octubre')) {
      await tap(tester, find.byKey(const Key('appointment-day')));
      await tapText(tester, '31');
      await shot(tester, 'cita_selector_fecha');
      // El selector de Material en español escribe "ACEPTAR" en mayúsculas.
      await tapText(tester, 'ACEPTAR');
    }
    await idle(tester, 2500);
    await shot(tester, 'cita_horas_libres');
    dump('horas libres Laura 31');
    final slot = find.byKey(
        ValueKey('slot-${DateTime(2026, 10, 31, 14).toIso8601String()}'));
    final slotTexts = find
        .byType(ChoiceChip)
        .evaluate()
        .map((e) => ((e.widget as ChoiceChip).label as Text).data)
        .toList();
    _log('slots: $slotTexts');
    var created = false;
    if (await waitFor(tester, slot, timeout: const Duration(seconds: 5))) {
      await tap(tester, slot);
    } else {
      // Ocupado por una corrida anterior de esta prueba: el primer hueco libre.
      _log('2:00 p. m. ocupado; se toma el primer hueco: ${slotTexts.first}');
      await tap(tester, find.byType(ChoiceChip).first);
    }
    await shot(tester, 'cita_formulario_lleno');
    await tapText(tester, 'Agendar', wait: 3000);
    await shot(tester, 'cita_creada');
    dump('tras agendar');
    // Cerrado el formulario, el nombre del cliente solo puede venir del bloque
    // de la agenda (con el formulario abierto también sale en "Cliente").
    final formClosed = find.text('Nueva cita').evaluate().isEmpty;
    if (!formClosed) {
      await tapText(tester, 'Cancelar');
    }
    created = formClosed &&
        await waitFor(tester, find.text('$clientName $clientLast'),
            timeout: const Duration(seconds: 8));
    check(created, 'la cita nueva aparece en la agenda del 31', allText());

    // ── Anticipo, abono y saldo ──
    Future<void> pay(String amount, String method, String label) async {
      if (!await openDetail(tester, '$clientName $clientLast')) {
        check(false, 'abrir la cita nueva para pagar ($label)', allText());
        return;
      }
      await shot(tester, 'detalle_antes_$label');
      dump('detalle antes de $label');
      final button = find.textContaining(RegExp('Registrar pago|Cobrar saldo'));
      if (button.evaluate().isEmpty) {
        check(false, 'botón de pago en el detalle ($label)', allText());
        await closeDialog(tester);
        return;
      }
      await tap(tester, button, wait: 2500);
      await shot(tester, 'pago_dialogo_$label');
      dump('diálogo de pago $label');
      if (amount.isNotEmpty) await type(tester, 'Monto recibido', amount);
      await tapText(tester, method, wait: 300);
      await tapText(tester, 'Confirmar pago', wait: 1500);
      // Un pago menor que el saldo pide confirmar el anticipo.
      final partial = find.text('Registrar anticipo');
      if (partial.evaluate().isNotEmpty) {
        await shot(tester, 'pago_confirmar_$label');
        dump('confirmación $label');
        await tap(tester, partial.last, wait: 3500);
      } else {
        await idle(tester, 2000);
      }
      await shot(tester, 'pago_hecho_$label');
      dump('tras pago $label');
    }

    if (created) {
      await pay('50000', 'Efectivo', 'anticipo');
      await pay('60000', 'Transferencia', 'abono');
      await pay('', 'Tarjeta de crédito', 'saldo');
      if (await openDetail(tester, '$clientName $clientLast')) {
        await shot(tester, 'detalle_pagada');
        final t = allText();
        dump('detalle pagada');
        check(!t.contains('Cobrar saldo') && !t.contains('Registrar pago'),
            'pagada del todo: ya no ofrece cobrar', t);
        await closeDialog(tester);
      }
    }

    // ── Estadísticas ──
    await openDrawerItem(tester, 'Informes');
    await idle(tester, 4000);
    await shot(tester, 'estadisticas');
    dump('estadísticas');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await idle(tester, 1500);
    await shot(tester, 'estadisticas_abajo');
    dump('estadísticas abajo');
    await back(tester);

    // ── Zona horaria ──
    await openDrawerItem(tester, 'Zona horaria');
    await idle(tester, 2500);
    await shot(tester, 'zona_horaria');
    dump('zona horaria');
    check(allText().contains('Bogota') || allText().contains('Bogotá'),
        'la pantalla de zona muestra Bogotá', allText());
    await back(tester);

    await logout(tester);

    // ───────────────────────── Empleada Ana ─────────────────────────
    await login(tester, _ana);
    await shot(tester, 'ana_agenda');
    await showDay(tester, DateTime(2026, 10, 30));
    await shot(tester, 'ana_dia_30');
    dump('Ana día 30');
    check(texts().contains('Valentina Castro'), 'Ana ve su cita (Valentina)');
    check(!texts().contains('Camila Torres'),
        'Ana no ve la cita de Laura (Camila)');
    if (await openDetail(tester, 'Valentina Castro')) {
      await shot(tester, 'ana_detalle_valentina');
      final t = allText();
      dump('Ana detalle');
      check(
          !t.contains('Editar') &&
              !t.contains('Registrar pago') &&
              !t.contains('Cobrar saldo'),
          'Ana no ve Editar ni cobrar',
          t);
      await closeDialog(tester);
    }
    await showDay(tester, DateTime(2026, 10, 31));
    await shot(tester, 'ana_dia_31');
    dump('Ana día 31');
    check(
        !allText().contains('$clientName $clientLast') &&
            !texts().contains('Sofía Ramírez'),
        'Ana no ve las citas de Laura del 31');
    await tap(tester, find.byType(DrawerButton));
    await shot(tester, 'ana_menu');
    final menu = allText();
    dump('Ana menú');
    check(
        !menu.contains('Personal') &&
            !menu.contains('Zona horaria') &&
            !menu.contains('Planes y suscripción'),
        'menú de Ana sin opciones de Owner',
        menu);
    check(menu.contains('EMPLEADO'), 'menú de Ana dice EMPLEADO');
    Navigator.of(tester.element(find.byType(Drawer))).pop();
    await idle(tester, 800);
    await openDrawerItem(tester, 'Informes');
    await idle(tester, 3000);
    await shot(tester, 'ana_informes');
    dump('Ana informes');
    await back(tester);
    await logout(tester);

    FlutterError.onError = originalOnError;
    _log('==== RESUMEN ====');
    for (final c in _checks) {
      _log(c);
    }
    expect(_failures, isEmpty, reason: _failures.join('\n'));
  });
}
