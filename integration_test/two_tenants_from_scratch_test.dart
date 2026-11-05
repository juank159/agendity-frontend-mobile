// Prueba 7.05: dos negocios desde cero, todo por la interfaz de la app real
// (macOS desktop) contra un backend con una BD vacía (`agendity_sim`).
//
//   flutter test integration_test/two_tenants_from_scratch_test.dart -d macos
//
// A: "Estudio Cejas y Pestañas" (America/Bogota). B: "Uñas Caracas"
// (America/Caracas). Registro y verificación del Owner, "Mi negocio" (zona y
// horario), categorías, servicios con color, empleadas con comisión y
// excepción, verificación de su email, clientes (mismo teléfono en A y B),
// citas de uno y varios servicios, horas libres, choque entre dispositivos,
// pagos (anticipo, abono y saldo), completar, comisiones, estadísticas,
// vista de la empleada y aislamiento entre negocios en el mismo teléfono.
//
// Fuera de la app solo se usa: el ayudante de códigos de verificación
// (`CODE_HELPER`, por defecto http://127.0.0.1:3999, como leer el correo) y,
// rotulado como "otro dispositivo", el API para reservar a la vez desde otro
// teléfono y para comprobar que el servidor rechaza lo que la app no ofrece.
//
// Para repetir solo algunas fases sobre los datos de una corrida anterior:
//   --dart-define=RUN=<sufijo> --dart-define=PHASES=a_future,a_complete
// Fases: a_setup, a_today, b_setup, b_today, a_future, b_future,
// a_complete, a_employee, b_complete, b_employee. Sueltas (no van en "all",
// ya las hace a_future): a_calendar, a_hours. Suelta: a_lunch (Mi negocio:
// lunes de 8 a 12 y de 2 a 7, el "12 a. m." por error y el color del
// teléfono frente al del negocio).
//
// "Hoy" en cada negocio: para poder COMPLETAR citas (solo se completa una cita
// que ya empezó y solo se agenda a futuro) la prueba abre una jornada
// extendida HOY (00:00-23:55) en el negocio y en sus empleadas, agenda en la
// primera hora libre, espera a que empiece, la completa y después deja el
// horario como estaba.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_calendar.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_tile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:integration_test/integration_test.dart';
import 'package:login_signup/core/config/env_config.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_feedback.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_day_notice.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_slot_sheet.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'support/app_driver.dart';

const _runDefine = String.fromEnvironment('RUN');
const _phases = String.fromEnvironment('PHASES', defaultValue: 'all');
const _codeHelper = String.fromEnvironment('CODE_HELPER',
    defaultValue: 'http://127.0.0.1:3999');

/// Sufijo de la corrida (5 dígitos): emails y teléfonos nuevos cada vez.
final String run = _runDefine.isNotEmpty
    ? _runDefine
    : DateTime.now().millisecondsSinceEpoch.toString().substring(8);

bool want(String phase) =>
    _phases == 'all' || _phases.split(',').contains(phase);

// ───────────────────────────── Datos ─────────────────────────────

class Svc {
  final String name;
  final String category;
  final int price;
  final int minutes;
  final String color;
  const Svc(this.name, this.category, this.price, this.minutes, this.color);
}

class Emp {
  final String first;
  final String last;
  final String key;
  final int general;
  final List<String> services;
  final Map<String, int> exceptions;
  const Emp(this.first, this.last, this.key, this.general, this.services,
      [this.exceptions = const {}]);
  String get fullName => '$first $last';
  String get email => '$key.$run@example.com';
}

class Cli {
  final String first;
  final String last;
  final String phone;
  const Cli(this.first, this.last, this.phone);
  String get fullName => '$first $last';
}

class Biz {
  final String code;
  final String name;
  final String zone;
  final String ownerFirst;
  final String ownerLast;
  final String ownerKey;
  final String phone;
  final List<String> categories;
  final List<Svc> services;
  final List<Emp> employees;
  final List<Cli> clients;

  /// Día (1 = lunes) → franjas de apertura; sin entrada = cerrado.
  final Map<int, List<(String, String)>> hours;
  const Biz({
    required this.code,
    required this.name,
    required this.zone,
    required this.ownerFirst,
    required this.ownerLast,
    required this.ownerKey,
    required this.phone,
    required this.categories,
    required this.services,
    required this.employees,
    required this.clients,
    required this.hours,
  });
  String get ownerEmail => '$ownerKey.$run@example.com';
  Svc svc(String name) => services.firstWhere((s) => s.name == name);
  DateTime now() => BusinessTimeZone.now(zone);
  DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }
}

/// Teléfono de 10 dígitos único por corrida.
String phone(String prefix, String tail) => '$prefix$run$tail';

final sharedPhone = phone('310', '01');

final bizA = Biz(
  code: 'A',
  name: 'Estudio Cejas y Pestañas',
  zone: 'America/Bogota',
  ownerFirst: 'Paula',
  ownerLast: 'Ríos',
  ownerKey: 'paula.a',
  phone: phone('300', '01'),
  categories: const ['Depilación', 'Cejas', 'Pestañas'],
  services: const [
    Svc('Depilación de axilas', 'Depilación', 25000, 20, '#4caf50'),
    Svc('Depilación de bozo', 'Depilación', 15000, 15, '#cddc39'),
    Svc('Cejas semipermanente', 'Cejas', 120000, 30, '#795548'),
    Svc('Diseño de cejas', 'Cejas', 35000, 30, '#ffc107'),
    Svc('Pestañas punto a punto', 'Pestañas', 150000, 120, '#673ab7'),
    Svc('Pestañas pelo a pelo', 'Pestañas', 180000, 150, '#e91e63'),
  ],
  employees: const [
    Emp('Ana', 'Gómez', 'ana', 30,
        ['Pestañas punto a punto', 'Pestañas pelo a pelo']),
    Emp('Laura', 'Pérez', 'laura', 50, [
      'Cejas semipermanente',
      'Diseño de cejas',
      'Depilación de axilas',
      'Depilación de bozo',
    ], {
      'Cejas semipermanente': 60
    }),
  ],
  clients: [
    Cli('Valentina', 'Castro', sharedPhone),
    Cli('Camila', 'Torres', phone('310', '02')),
    Cli('Isabella', 'Rincón', phone('310', '03')),
  ],
  // De lunes a sábado de 8 a 19, salvo el día partido (13.03): abre a las
  // 8:30, cierra a mediodía y vuelve a las 14:00 (D-26: el almuerzo solo
  // cierra el link público; en la app se agenda de corrido).
  hours: {
    for (var day = DateTime.monday; day <= DateTime.saturday; day++)
      day: day == splitWeekday ? splitHours : const [('08:00', '19:00')],
  },
);

/// Día de la semana con horario partido en A: el sábado o, si hoy es sábado
/// (la fase de hoy abre ese día entero), el viernes. Nunca es el día X ni el
/// Y (son los siguientes días hábiles a hoy y no pasan del lunes y martes
/// cuando hoy es viernes o sábado).
int get splitWeekday =>
    BusinessTimeZone.now('America/Bogota').weekday == DateTime.saturday
        ? DateTime.friday
        : DateTime.saturday;

const splitHours = [('08:30', '12:00'), ('14:00', '19:00')];

final bizB = Biz(
  code: 'B',
  name: 'Uñas Caracas',
  zone: 'America/Caracas',
  ownerFirst: 'Daniela',
  ownerLast: 'Pérez',
  ownerKey: 'daniela.b',
  phone: phone('300', '02'),
  categories: const ['Manos', 'Pies'],
  services: const [
    Svc('Manicure', 'Manos', 30000, 45, '#e91e63'),
    Svc('Uñas acrílicas', 'Manos', 90000, 90, '#673ab7'),
    Svc('Mantenimiento acrílicas', 'Manos', 60000, 60, '#00bcd4'),
    Svc('Diseño de cejas', 'Manos', 25000, 30, '#ffc107'),
    Svc('Pedicure', 'Pies', 40000, 60, '#009688'),
  ],
  employees: const [
    Emp('Sofía', 'Rangel', 'sofia', 40, [
      'Manicure',
      'Uñas acrílicas',
      'Mantenimiento acrílicas',
      'Diseño de cejas',
      'Pedicure',
    ]),
  ],
  clients: [
    Cli('María', 'Fernández', sharedPhone),
    Cli('Gabriela', 'Suárez', phone('310', '04')),
  ],
  hours: const {
    1: [('09:00', '18:00')],
    2: [('09:00', '18:00')],
    3: [('09:00', '18:00')],
    4: [('09:00', '18:00')],
    5: [('09:00', '18:00')],
  },
);

const _dayNames = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// Siguiente día hábil (lunes a viernes) después de [from].
DateTime nextWeekday(DateTime from) {
  var d = DateTime(from.year, from.month, from.day + 1);
  while (d.weekday > DateTime.friday) {
    d = DateTime(d.year, d.month, d.day + 1);
  }
  return d;
}

DateTime nextSaturday(DateTime from) {
  var d = DateTime(from.year, from.month, from.day + 1);
  while (d.weekday != DateTime.saturday) {
    d = DateTime(d.year, d.month, d.day + 1);
  }
  return d;
}

DateTime at(DateTime day, int hour, [int minute = 0]) =>
    DateTime(day.year, day.month, day.day, hour, minute);

String hm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String cop(int value) {
  final s = value.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '\$ $b';
}

// ───────────────────────── Fuera de la app ─────────────────────────

/// Código de verificación que llegó al correo de [email] (ayudante).
Future<String> verificationCode(WidgetTester tester, String email) async {
  final dio = Dio(BaseOptions(baseUrl: _codeHelper));
  for (var i = 0; i < 20; i++) {
    try {
      final r = await dio
          .get<Map<String, dynamic>>('/', queryParameters: {'email': email});
      final code = '${r.data?['code'] ?? ''}';
      if (code.length == 6) return code;
    } catch (e) {
      log('ayudante de códigos: $e');
    }
    await idle(tester, 1000);
  }
  return '';
}

/// "Otro dispositivo": la misma cuenta desde otro teléfono, por el API.
class OtherDevice {
  final Dio dio =
      Dio(BaseOptions(baseUrl: EnvConfig.apiUrl, validateStatus: (_) => true));
  String userId = '';

  Future<bool> login(WidgetTester tester, String email) async {
    for (var i = 0; i < 3; i++) {
      final r = await dio.post<dynamic>('/auth/login',
          data: {'email': email, 'password': testPassword});
      if (r.statusCode == 429) {
        await waitThrottle(tester, 'login del otro dispositivo');
        continue;
      }
      final data = r.data;
      if (data is Map && data['token'] is String) {
        dio.options.headers['Authorization'] = 'Bearer ${data['token']}';
        userId = '${(data['user'] as Map)['id']}';
        return true;
      }
      log('otro dispositivo: login ${r.statusCode} ${r.data}');
      return false;
    }
    return false;
  }

  Future<String?> idOf(String path, bool Function(Map) where) async {
    final r = await dio.get<dynamic>(path);
    final data = r.data;
    final list = data is List
        ? data
        : (data is Map && data['data'] is List ? data['data'] as List : []);
    for (final item in list) {
      if (item is Map && where(item)) return '${item['id']}';
    }
    return null;
  }

  Future<Response<dynamic>> book(
          String clientId, List<String> serviceIds, DateTime instant) =>
      dio.post<dynamic>('/appointments', data: {
        'client_id': clientId,
        'professional_id': userId,
        'service_ids': serviceIds,
        'date': instant.toUtc().toIso8601String(),
      });
}

/// Instante real de una hora de pared de [zone].
DateTime instantIn(String zone, DateTime wall) =>
    BusinessTimeZone.toInstant(wall, zone);

// ───────────────────────── Pasos de la app ─────────────────────────

Finder semanticsButton(String label) => find
    .byWidgetPredicate((w) => w is Semantics && w.properties.label == label);

Future<bool> registerOwner(WidgetTester tester, Biz biz) async {
  await waitFor(tester, find.text('Iniciar sesión'),
      timeout: const Duration(seconds: 30));
  await tapText(tester, 'Regístrate', wait: 1500);
  await shot(tester, '${biz.code}_registro');
  await type(tester, 'Nombre', biz.ownerFirst);
  await type(tester, 'Apellidos', biz.ownerLast);
  await type(tester, 'Nombre del negocio (opcional)', biz.name);
  await type(tester, 'Teléfono', biz.phone);
  await type(tester, 'Correo electrónico', biz.ownerEmail);
  await type(tester, 'Contraseña', testPassword);
  await shot(tester, '${biz.code}_registro_lleno');
  for (var attempt = 0; attempt < 3; attempt++) {
    await tapText(tester, 'Crear cuenta', wait: 500);
    if (await waitFor(
        tester,
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data == 'Verifica tu correo' ||
                (w.data ?? '').contains('ya está registrado'))),
        timeout: const Duration(seconds: 20))) {
      break;
    }
    if (!isThrottled) break;
    await dismissDialogs(tester);
    await waitThrottle(tester, 'registro');
  }
  if (allText().contains('ya está registrado')) {
    // Corrida reanudada (RUN fijo): el Owner ya existe; entra con su cuenta.
    log('${biz.code}: el Owner ya existía; se inicia sesión');
    await dismissDialogs(tester);
    await back(tester);
    await login(tester, biz.ownerEmail);
    return find.byTooltip('Nueva cita').evaluate().isNotEmpty;
  }
  final ok = find.text('Verifica tu correo').evaluate().isNotEmpty;
  check(ok, '${biz.code}: registro del Owner lleva a verificar el correo',
      ok ? null : allText());
  if (!ok) return false;

  // Código pedido al abrir la pantalla (como si llegara al correo).
  await idle(tester, 3000);
  if (allText().contains('No se pudo enviar el código')) {
    await dismissDialogs(tester);
    await waitThrottle(tester, 'código del Owner');
    await tapText(tester, 'Reenviar código', wait: 3000);
  }
  await shot(tester, '${biz.code}_verificar_correo');
  final code = await verificationCode(tester, biz.ownerEmail);
  check(code.length == 6, '${biz.code}: llegó el código de verificación');
  await enterPin(tester, code);
  if (find.text('Verificar correo').evaluate().isNotEmpty &&
      find.byTooltip('Nueva cita').evaluate().isEmpty) {
    await tapText(tester, 'Verificar correo', wait: 500);
  }
  final home = await waitFor(tester, find.byTooltip('Nueva cita'),
      timeout: const Duration(seconds: 20));
  check(home, '${biz.code}: correo verificado y entra a la agenda',
      home ? null : allText());
  await idle(tester, 2500);
  await shot(tester, '${biz.code}_agenda_vacia');
  return home;
}

/// "Mi negocio": nombre (del registro), zona y horario de apertura.
Future<void> configureBusiness(WidgetTester tester, Biz biz) async {
  await openDrawerItem(tester, 'Mi negocio');
  await waitFor(tester, find.byKey(const Key('business-name')));
  await idle(tester, 1500);
  final name = tester
          .widget<TextField>(find.byKey(const Key('business-name')))
          .controller
          ?.text ??
      '';
  check(name == biz.name,
      '${biz.code}: el nombre del registro está en Mi negocio', name);
  final link = find.byKey(const Key('booking-link'));
  check(link.evaluate().isNotEmpty, '${biz.code}: tiene link de reservas');
  await shot(tester, '${biz.code}_mi_negocio');

  if (!allText().contains(biz.zone)) {
    await tap(tester, find.widgetWithText(OutlinedButton, 'Cambiar'),
        wait: 1200);
    await type(tester, 'Buscar zona', biz.zone.split('/').last);
    await idle(tester, 800);
    await tapText(tester, biz.zone, wait: 1000);
    await shot(tester, '${biz.code}_confirmar_zona');
    await tapText(tester, 'Cambiar zona', wait: 3000);
  }
  check(allText().contains(biz.zone),
      '${biz.code}: zona del negocio ${biz.zone}', allText());
  if (biz.zone != 'America/Bogota') {
    // El aviso va arriba de la lista (perezosa): subir antes de leerlo.
    await tester.drag(
        find
            .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down)
            .first,
        const Offset(0, 5000),
        warnIfMissed: false);
    await idle(tester, 600);
    check(
        allText().contains('Horas en la zona del negocio'),
        '${biz.code}: aviso de que las horas van en la zona del negocio '
        '(el Mac está en Bogotá)');
  }

  await setOpeningHours(tester, biz, biz.hours);
  await shot(tester, '${biz.code}_horario_guardado');
  await back(tester);
}

/// Deja el horario de apertura del negocio como [hours] (ya en Mi negocio):
/// por día, las franjas en orden; quita las que sobran ("Quitar franja del
/// Lunes", con el nombre del día tal cual) y añade las que faltan ("Añadir
/// franja", `opening-add-<día>`).
Future<void> setOpeningHours(WidgetTester tester, Biz biz,
    Map<int, List<(String, String)>> hours) async {
  final limit = find.byKey(const Key('opening-hours-enabled'));
  await waitFor(tester, limit);
  if (!tester.widget<SwitchListTile>(limit).value) await tap(tester, limit);
  for (var day = 1; day <= 7; day++) {
    final dayName = _dayNames[day - 1];
    final toggle = find.byKey(Key('opening-day-$day'));
    final open = tester.widget<Switch>(toggle).value;
    final wanted = hours[day] ?? const <(String, String)>[];
    if (wanted.isEmpty) {
      if (open) await tap(tester, toggle, wait: 400);
      continue;
    }
    if (!open) await tap(tester, toggle, wait: 400);
    final remove = find.byTooltip('Quitar franja del $dayName');
    while (remove.evaluate().length > wanted.length) {
      await tap(tester, remove.last, wait: 300);
    }
    for (var i = 0; i < wanted.length; i++) {
      final openBtn = semanticsButton('$dayName, franja ${i + 1}, apertura');
      final closeBtn = semanticsButton('$dayName, franja ${i + 1}, cierre');
      if (openBtn.evaluate().isEmpty) {
        await tap(tester, find.byKey(Key('opening-add-$day')), wait: 400);
      }
      if (!_buttonShows(tester, openBtn, wanted[i].$1)) {
        await pickTime(tester, openBtn, wanted[i].$1);
      }
      if (!_buttonShows(tester, closeBtn, wanted[i].$2)) {
        await pickTime(tester, closeBtn, wanted[i].$2);
      }
    }
    if (wanted.length > 1) {
      check(
          remove.evaluate().length == wanted.length,
          '${biz.code}: el ${dayName.toLowerCase()} queda con '
          '${wanted.length} franjas',
          allText());
    }
  }
  await shot(tester, '${biz.code}_horario_editado');
  final save = find.text('Guardar horario');
  if (save.evaluate().isEmpty) {
    log('${biz.code}: el horario ya estaba así');
    return;
  }
  await tap(tester, save, wait: 2500);
  check(find.text('Guardar horario').evaluate().isEmpty,
      '${biz.code}: horario de apertura guardado', allText());
}

/// El botón ya muestra [hhmm] (`13:30`), que se ve en 12 h (D-23):
/// "Abre: 1:30 p. m.".
bool _buttonShows(WidgetTester tester, Finder button, String hhmm) => find
    .descendant(
        of: button, matching: find.textContaining(': ${formatHhmm(hhmm)}'))
    .evaluate()
    .isNotEmpty;

Future<void> createCategories(WidgetTester tester, Biz biz) async {
  await openDrawerItem(tester, 'Servicios');
  await tap(tester, find.byTooltip('Categorías'), wait: 1500);
  await idle(tester, 1500);
  for (final name in biz.categories) {
    if (find.text(name).evaluate().isNotEmpty) continue;
    final fab = find.widgetWithText(AppGradientButton, 'Categoría');
    if (fab.evaluate().isNotEmpty) {
      await tap(tester, fab, wait: 1200);
    } else {
      await tapText(tester, 'Crear categoría', wait: 1200);
    }
    await type(tester, 'Nombre de la categoría', name);
    await tap(tester, find.widgetWithText(FilledButton, 'Crear categoría'),
        wait: 2000);
    check(
        await waitFor(tester, find.text('Categorías de servicio')) &&
            await waitFor(tester, find.text(name)),
        '${biz.code}: categoría $name creada',
        allText());
  }
  await shot(tester, '${biz.code}_categorias');
  await back(tester);
}

Future<void> createServices(WidgetTester tester, Biz biz) async {
  await idle(tester, 1500);
  for (final s in biz.services) {
    if (find.text(s.name).evaluate().isNotEmpty) continue;
    final fab = find.widgetWithText(AppGradientButton, 'Servicio');
    if (fab.evaluate().isNotEmpty) {
      await tap(tester, fab, wait: 1500);
    } else {
      await tapText(tester, 'Crear servicio', wait: 1500);
    }
    await waitFor(tester, find.text('Nuevo servicio'));
    await type(tester, 'Nombre del servicio', s.name);
    await type(tester, 'Precio', '${s.price}');
    await tapText(tester, 'Duración');
    final durationOk = await pickDuration(tester, s.minutes);
    await tapText(tester, 'Categoría');
    await tap(
        tester,
        find.descendant(
            of: find.byType(AlertDialog), matching: find.text(s.category)),
        wait: 800);
    final color = find.byKey(ValueKey('service-color-${s.color}'));
    await tap(tester, color, wait: 400);
    final form = allText();
    check(durationOk && form.contains(_durationText(s.minutes)),
        '${biz.code}: ${s.name} con ${s.minutes} min', form);
    if (s == biz.services.first) {
      await shot(tester, '${biz.code}_servicio_form');
    }
    await tap(tester, find.widgetWithText(FilledButton, 'Guardar'), wait: 2500);
    final saved = await waitFor(tester, find.text('Servicios')) &&
        await waitFor(tester, find.text(s.name));
    check(saved, '${biz.code}: servicio ${s.name} guardado', allText());
    if (!saved && find.text('Nuevo servicio').evaluate().isNotEmpty) {
      await shot(tester, '${biz.code}_servicio_error');
      await back(tester);
    }
  }
  await shot(tester, '${biz.code}_servicios');
  final listed = await scrollTexts(tester);
  check(
      biz.services.every((s) => listed.contains(s.name)) &&
          biz.services.every((s) => listed.contains(cop(s.price))),
      '${biz.code}: el catálogo muestra los ${biz.services.length} servicios '
      'con su precio',
      listed);
}

String _durationText(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m min';
}

/// Ajusta el `Slider` visible hasta [value] (arrastres cortos).
Future<double> setSlider(WidgetTester tester, Finder slider, int value) async {
  for (var i = 0; i < 12; i++) {
    final current = tester.widget<Slider>(slider).value;
    if (current.round() == value) break;
    final width = tester.getSize(slider).width - 48;
    await tester.drag(slider, Offset((value - current) * width / 100, 0));
    await idle(tester, 300);
  }
  return tester.widget<Slider>(slider).value;
}

Future<void> createEmployees(WidgetTester tester, Biz biz) async {
  await openDrawerItem(tester, 'Personal');
  await idle(tester, 1500);
  for (final e in biz.employees) {
    if (find.text(e.fullName).evaluate().isNotEmpty) continue;
    await tap(tester, find.byTooltip('Agregar profesional'), wait: 2000);
    await waitFor(tester, find.text('Nuevo profesional'));
    await type(tester, 'Nombre *', e.first);
    await type(tester, 'Apellido *', e.last);
    await type(tester, 'Email *', e.email);
    await type(tester, 'Teléfono *',
        phone('301', '${biz.employees.indexOf(e)}${biz.code == 'A' ? 1 : 2}'));
    await type(tester, 'Contraseña *', testPassword);
    await type(tester, 'Comisión general (%)', '${e.general}');
    await waitFor(tester, find.byType(CheckboxListTile));
    // Primero las excepciones (su interruptor es el único "Usar la general").
    final ordered = [
      ...e.services.where(e.exceptions.containsKey),
      ...e.services.where((s) => !e.exceptions.containsKey(s)),
    ];
    for (final s in ordered) {
      final tile = find.widgetWithText(CheckboxListTile, s);
      if (tile.evaluate().isEmpty) {
        check(false, '${biz.code}: ${e.first}: el servicio $s se puede asignar',
            allText());
        continue;
      }
      await tap(tester, tile, wait: 400);
      final own = e.exceptions[s];
      if (own != null) {
        final general = find.byWidgetPredicate((w) =>
            w is SwitchListTile &&
            w.title is Text &&
            ((w.title as Text).data ?? '').startsWith('Usar la general'));
        check(
            find
                .descendant(
                    of: general, matching: find.textContaining('${e.general}'))
                .evaluate()
                .isNotEmpty,
            '${biz.code}: ${e.first}: "Usar la general (${e.general} %)"',
            allText());
        await tap(tester, general.first, wait: 500);
        final slider = find.byType(Slider);
        final value = await setSlider(tester, slider, own);
        check(value.round() == own,
            '${biz.code}: ${e.first}: excepción de $own % en $s', value);
        await shot(tester, '${biz.code}_${e.key}_excepcion');
      }
    }
    // Horario: el de alta (lunes a viernes 9-18) y además el sábado.
    final saturday = find.widgetWithText(SwitchListTile, 'Sábado');
    if (!tester.widget<SwitchListTile>(saturday).value) {
      await tap(tester, saturday, wait: 400);
    }
    await shot(tester, '${biz.code}_${e.key}_formulario');
    await tap(tester, find.text('Crear profesional'), wait: 2500);

    // Verificación del email (la empleada lee el código en su correo).
    final verifyOpen = await waitFor(tester, find.text('Verificar email'),
        timeout: const Duration(seconds: 20));
    check(verifyOpen, '${biz.code}: ${e.first} creada; pide verificar su email',
        allText());
    if (!verifyOpen) {
      await shot(tester, '${biz.code}_${e.key}_error');
      continue;
    }
    await idle(tester, 3000);
    if (allText().contains('No se pudo enviar el código')) {
      await dismissDialogs(tester);
      await waitThrottle(tester, 'código de ${e.first}');
      await tapText(tester, 'Reenviar código', wait: 3000);
    }
    await shot(tester, '${biz.code}_${e.key}_verificar');
    final code = await verificationCode(tester, e.email);
    check(code.length == 6, '${biz.code}: llegó el código de ${e.first}');
    await enterPin(tester, code);
    await waitGone(tester, find.text('Verificar email'),
        timeout: const Duration(seconds: 15));
    if (find.text('Verificar email').evaluate().isNotEmpty) {
      await tap(tester, find.widgetWithText(FilledButton, 'Verificar email'),
          wait: 3000);
    }
    await waitFor(tester, find.text('Profesionales'));
    await idle(tester, 2500);
    final card =
        find.ancestor(of: find.text(e.fullName), matching: find.byType(Card));
    final active = card.evaluate().isNotEmpty &&
        find
            .descendant(of: card.first, matching: find.text('Activo'))
            .evaluate()
            .isNotEmpty;
    check(active, '${biz.code}: ${e.fullName} verificada y activa', allText());
  }
  await shot(tester, '${biz.code}_personal');
  await back(tester);
}

Future<void> createClients(WidgetTester tester, Biz biz) async {
  await openDrawerItem(tester, 'Clientela');
  await idle(tester, 1500);
  for (final c in biz.clients) {
    if (find.textContaining(c.fullName).evaluate().isNotEmpty) continue;
    await tap(tester, find.byTooltip('Agregar cliente'), wait: 800);
    await tapText(tester, 'Nuevo cliente', wait: 1500);
    await type(tester, 'Nombre *', c.first);
    await type(tester, 'Apellido', c.last);
    await type(tester, 'Teléfono móvil *', c.phone);
    await tapText(tester, 'Guardar cliente', wait: 2500);
    final ok = await waitFor(tester, find.textContaining(c.fullName));
    check(ok, '${biz.code}: cliente ${c.fullName} (${c.phone}) creado',
        allText());
    if (!ok) {
      await shot(tester, '${biz.code}_cliente_error');
      if (find.text('Guardar cliente').evaluate().isNotEmpty) {
        await back(tester);
      }
    }
  }
  await shot(tester, '${biz.code}_clientes');
  await back(tester);
}

/// Horas libres que ofrece el formulario abierto.
List<DateTime> slotTimes() => find
    .byType(ChoiceChip)
    .evaluate()
    .map((e) => (e.widget.key! as ValueKey<String>).value.substring(5))
    .map(DateTime.parse)
    .toList();

String slotsText(List<DateTime> slots) => slots.map(hm).join(' ');

/// Abre el formulario de cita nueva en [day] y lo llena hasta mostrar las
/// horas libres. Devuelve esas horas (vacío si no hay).
Future<List<DateTime>> openAppointmentForm(WidgetTester tester,
    {String? professional,
    required List<String> services,
    required Cli client,
    required DateTime day}) async {
  await showDay(tester, day);
  await tap(tester, find.byTooltip('Nueva cita'), wait: 2500);
  return fillAppointmentForm(tester,
      professional: professional, services: services, client: client);
}

/// Llena el formulario de cita ya abierto (por "Nueva cita" o tocando una
/// hora de la agenda) y devuelve las horas libres que ofrece.
Future<List<DateTime>> fillAppointmentForm(WidgetTester tester,
    {String? professional,
    required List<String> services,
    required Cli client}) async {
  if (professional != null) {
    await tap(tester, find.byKey(const Key('appointment-professional')));
    await tap(
        tester,
        find.descendant(
            of: find.byType(Dialog).last, matching: find.text(professional)),
        wait: 1500);
  }
  await tap(tester, find.byKey(const Key('appointment-services')));
  for (final s in services) {
    final tile = find.widgetWithText(CheckboxListTile, s);
    await waitFor(tester, tile);
    await tap(tester, tile, wait: 400);
  }
  await tapText(tester, 'Listo');
  await tap(tester, find.byKey(const Key('appointment-client')));
  await type(tester, 'Buscar por nombre o teléfono', client.first);
  await idle(tester, 1500);
  await tap(
      tester,
      find.descendant(
          of: find.byType(Dialog).last, matching: find.text(client.fullName)),
      wait: 800);
  final ready = await waitFor(
      tester,
      find.byWidgetPredicate((w) =>
          w is ChoiceChip ||
          (w is Text && (w.data ?? '').startsWith('No hay horas libres'))),
      timeout: const Duration(seconds: 15));
  if (!ready) log('horas libres no cargaron: ${allText()}');
  return slotTimes();
}

/// Elige [slot] (o el primero) y agenda. `null` si no se pudo.
Future<DateTime?> chooseSlotAndSave(WidgetTester tester,
    {DateTime? slot, String? label}) async {
  final slots = slotTimes();
  if (slots.isEmpty) {
    await tapText(tester, 'Cancelar', wait: 1000);
    return null;
  }
  final chosen = slot ?? slots.first;
  final chip = find.byKey(ValueKey('slot-${chosen.toIso8601String()}'));
  if (chip.evaluate().isEmpty) {
    log('la hora ${hm(chosen)} no está libre: ${slotsText(slots)}');
    await tapText(tester, 'Cancelar', wait: 1000);
    return null;
  }
  await tap(tester, chip, wait: 400);
  if (label != null) await shot(tester, label);
  await tap(tester, find.widgetWithText(FilledButton, 'Agendar'), wait: 3000);
  final closed = await waitGone(tester, find.text('Nueva cita'),
      timeout: const Duration(seconds: 10));
  if (!closed) {
    log('el formulario no se cerró: ${allText()}');
    await tapText(tester, 'Cancelar', wait: 1000);
    return null;
  }
  return chosen;
}

/// Registra un pago desde el detalle de la cita de [client].
Future<void> pay(WidgetTester tester, Biz biz, Cli client, String amount,
    String method, String label) async {
  if (!await openDetail(tester, client.fullName)) {
    check(false, '${biz.code}: abrir la cita de ${client.first} ($label)',
        allText());
    return;
  }
  final button = find.textContaining(RegExp('Registrar pago|Cobrar saldo'));
  if (button.evaluate().isEmpty) {
    check(false, '${biz.code}: botón de pago ($label)', allText());
    await closeDialog(tester);
    return;
  }
  await tap(tester, button, wait: 2500);
  await shot(tester, '${biz.code}_pago_$label');
  if (amount.isNotEmpty) await type(tester, 'Monto recibido', amount);
  await tapText(tester, method, wait: 300);
  await tapText(tester, 'Confirmar pago', wait: 1500);
  final partial = find.text('Registrar anticipo');
  if (partial.evaluate().isNotEmpty) {
    await tap(tester, partial.last, wait: 3500);
  } else {
    await idle(tester, 2500);
  }
}

/// Estado (cita · pago) que muestra el detalle de la cita de [client].
Future<String> detailText(WidgetTester tester, Cli client,
    {String? shotName}) async {
  if (!await openDetail(tester, client.fullName)) return '';
  final t = allText();
  if (shotName != null) await shot(tester, shotName);
  await closeDialog(tester);
  return t;
}

/// Abre la ficha de [e] para editar (Personal → opciones → Editar).
Future<void> openEditEmployee(WidgetTester tester, Emp e) async {
  await tap(tester, find.byTooltip('Opciones de ${e.fullName}'), wait: 1000);
  await tapText(tester, 'Editar', wait: 2500);
  await waitFor(tester, find.text('Editar profesional'));
  await idle(tester, 1500);
}

/// Horario de [e] en el día [weekday]: `null` = no trabaja.
Future<void> setEmployeeDay(WidgetTester tester, Biz biz, Emp e, int weekday,
    (String, String)? hours) async {
  await openDrawerItem(tester, 'Personal');
  await idle(tester, 1500);
  await openEditEmployee(tester, e);
  final dayLabel = _dayNames[weekday - 1];
  final toggle = find.widgetWithText(SwitchListTile, dayLabel);
  // El formulario es una lista perezosa: el horario no existe hasta bajar.
  await tester.scrollUntilVisible(toggle, 300,
      scrollable: find
          .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down)
          .first);
  await tester.ensureVisible(toggle);
  final on = tester.widget<SwitchListTile>(toggle).value;
  if ((hours != null) != on) await tap(tester, toggle, wait: 400);
  if (hours != null) {
    // Una sola franja (13.06: el día puede tener varias).
    final extra = find.byWidgetPredicate((w) =>
        w is Tooltip &&
        (w.message ?? '').startsWith('Quitar franja ') &&
        (w.message ?? '').endsWith(' del ${dayLabel.toLowerCase()}') &&
        !(w.message ?? '').startsWith('Quitar franja 1 '));
    while (extra.evaluate().isNotEmpty) {
      await tap(tester, extra.last, wait: 300);
    }
    final start = semanticsButton('$dayLabel, hora de inicio');
    final end = semanticsButton('$dayLabel, hora de fin');
    if (!_buttonShows(tester, start, hours.$1)) {
      await pickTime(tester, start, hours.$1);
    }
    if (!_buttonShows(tester, end, hours.$2)) {
      await pickTime(tester, end, hours.$2);
    }
  }
  await shot(tester, '${biz.code}_${e.key}_horario_$weekday');
  await tap(tester, find.text('Guardar cambios'), wait: 3000);
  final saved = await waitFor(tester, find.text('Profesionales'),
      timeout: const Duration(seconds: 10));
  check(
      saved,
      '${biz.code}: horario de ${e.first} del ${dayLabel.toLowerCase()} '
      '${hours == null ? 'libre' : '${hours.$1}-${hours.$2}'}',
      allText());
  await back(tester);
}

/// Jornada extendida HOY (00:00-23:55) en el negocio y sus empleadas.
Future<void> openTodayFully(WidgetTester tester, Biz biz) async {
  final weekday = biz.today().weekday;
  await openDrawerItem(tester, 'Mi negocio');
  await idle(tester, 2000);
  await setOpeningHours(tester, biz, {
    ...biz.hours,
    weekday: const [('00:00', '23:55')]
  });
  await back(tester);
  for (final e in biz.employees) {
    await setEmployeeDay(tester, biz, e, weekday, ('00:00', '23:55'));
  }
}

/// Deshace [openTodayFully].
Future<void> restoreToday(WidgetTester tester, Biz biz) async {
  final weekday = biz.today().weekday;
  await openDrawerItem(tester, 'Mi negocio');
  await idle(tester, 2000);
  await setOpeningHours(tester, biz, biz.hours);
  await back(tester);
  for (final e in biz.employees) {
    await setEmployeeDay(tester, biz, e, weekday,
        weekday <= DateTime.saturday ? ('09:00', '18:00') : null);
  }
}

/// Espera a que la sincronización deje la cita de [client] en el servidor y
/// la agenda la vuelva a pintar.
Future<void> settle(WidgetTester tester, [int ms = 6000]) => idle(tester, ms);

// ───────────────────────────── Fases ─────────────────────────────

Future<void> phaseSetup(WidgetTester tester, Biz biz) async {
  log('== ${biz.code}: alta desde cero (${biz.name}, ${biz.zone}) ==');
  if (!await registerOwner(tester, biz)) return;
  // Negocio nuevo en un teléfono donde ya trabajó otro negocio: nada ajeno.
  if (biz == bizB) await isolationEmpty(tester, biz);
  await configureBusiness(tester, biz);
  await createCategories(tester, biz);
  await createServices(tester, biz);
  await back(tester);
  await createEmployees(tester, biz);
  await createClients(tester, biz);
  await logout(tester);
}

/// B recién creado en el mismo teléfono que A: no ve nada de A.
Future<void> isolationEmpty(WidgetTester tester, Biz biz) async {
  final dayX = nextWeekday(biz.today());
  await showDay(tester, dayX);
  await shot(tester, '${biz.code}_agenda_vacia_diaX');
  check(!bizA.clients.any((c) => allText().contains(c.fullName)),
      '${biz.code}: la agenda nueva no muestra citas de A', allText());
  await openDrawerItem(tester, 'Servicios');
  await idle(tester, 2000);
  await shot(tester, '${biz.code}_servicios_vacio');
  check(
      allText().contains('Aún no hay servicios') &&
          !bizA.services.any((s) => allText().contains(s.name)),
      '${biz.code}: catálogo vacío (nada de A)',
      allText());
  await back(tester);
  await openDrawerItem(tester, 'Clientela');
  await idle(tester, 2000);
  check(!bizA.clients.any((c) => allText().contains(c.fullName)),
      '${biz.code}: clientela vacía (nada de A)', allText());
  await back(tester);
  await openDrawerItem(tester, 'Personal');
  await idle(tester, 2000);
  check(!bizA.employees.any((e) => allText().contains(e.fullName)),
      '${biz.code}: sin profesionales de A', allText());
  await back(tester);
}

/// Hoy: jornada extendida y citas en la primera hora libre (para poder
/// completarlas después), con anticipo, abono y saldo.
Future<void> phaseToday(WidgetTester tester, Biz biz) async {
  log('== ${biz.code}: citas de hoy ==');
  await login(tester, biz.ownerEmail);
  await openTodayFully(tester, biz);
  final today = biz.today();
  final now = biz.now();

  final plans = biz == bizA
      ? [
          (
            bizA.employees[1],
            [
              'Cejas semipermanente',
              'Depilación de bozo',
              'Depilación de axilas'
            ],
            bizA.clients[0],
            160000,
            65
          ),
          (
            bizA.employees[0],
            ['Pestañas punto a punto'],
            bizA.clients[1],
            150000,
            120
          ),
        ]
      : [
          (bizB.employees[0], ['Manicure'], bizB.clients[0], 30000, 45),
        ];
  for (final (emp, services, client, total, minutes) in plans) {
    final slots = await openAppointmentForm(tester,
        professional: emp.fullName,
        services: services,
        client: client,
        day: today);
    final form = allText();
    if (services.length > 1) {
      check(
          form.contains('${cop(total)} · ${_durationText(minutes)}'),
          '${biz.code}: varios servicios: total ${cop(total)} y '
          '${_durationText(minutes)} (suma)',
          form);
    }
    await shot(tester, '${biz.code}_hoy_${emp.key}_horas');
    check(
        slots.every((s) => s.isAfter(now)),
        '${biz.code}: hoy solo ofrece horas futuras (ahora ${hm(now)}; '
        'primera ${slots.isEmpty ? '-' : hm(slots.first)})',
        slotsText(slots));
    final lastEnd = at(today, 23, 55);
    check(
        slots.every((s) => !s.add(Duration(minutes: minutes)).isAfter(lastEnd)),
        '${biz.code}: ninguna hora de hoy termina después del cierre',
        slotsText(slots));
    final chosen = await chooseSlotAndSave(tester,
        label: '${biz.code}_hoy_${emp.key}_elegida');
    if (chosen == null) {
      skip('${biz.code}: cita de hoy de ${emp.first}',
          'no quedan horas hoy para ${_durationText(minutes)}');
      continue;
    }
    await settle(tester);
    final t = await detailText(tester, client,
        shotName: '${biz.code}_hoy_${emp.key}_detalle');
    final end = chosen.add(Duration(minutes: minutes));
    check(
        t.contains(cop(total)) &&
            t.contains(_durationText(minutes)) &&
            t.contains('Pendiente') &&
            t.contains('Sin pagar'),
        '${biz.code}: cita de hoy ${client.first} ${hm(chosen)}-${hm(end)} '
        '${cop(total)}, pendiente y sin pagar',
        t);
  }

  // Pagos: anticipo → abono → saldo (A: Laura; B: Sofía) y total (A: Ana).
  final payer = plans.first;
  final client = payer.$3;
  final total = payer.$4;
  if (await openDetail(tester, client.fullName)) {
    await closeDialog(tester);
    final first = total == 160000 ? 50000 : 10000;
    final second = total == 160000 ? 60000 : 0;
    await pay(tester, biz, client, '$first', 'Efectivo', 'anticipo');
    await settle(tester, 3000);
    var t =
        await detailText(tester, client, shotName: '${biz.code}_tras_anticipo');
    check(t.contains('Anticipo') && t.contains('Confirmada'),
        '${biz.code}: tras el anticipo: Confirmada · Anticipo (PARTIAL)', t);
    if (second > 0) {
      await pay(tester, biz, client, '$second', 'Transferencia', 'abono');
      await settle(tester, 3000);
      t = await detailText(tester, client, shotName: '${biz.code}_tras_abono');
      check(t.contains('Anticipo') && t.contains('Cobrar saldo'),
          '${biz.code}: tras el abono sigue en Anticipo con saldo', t);
    }
    await pay(tester, biz, client, '', 'Tarjeta de crédito', 'saldo');
    await settle(tester, 3000);
    t = await detailText(tester, client, shotName: '${biz.code}_pagada');
    check(
        t.contains('Pagada') &&
            !t.contains('Cobrar saldo') &&
            !t.contains('Registrar pago'),
        '${biz.code}: tras el saldo: Pagada (COMPLETED), sin botón de cobro',
        t);
  }
  if (plans.length > 1 && await openDetail(tester, plans[1].$3.fullName)) {
    await closeDialog(tester);
    await pay(tester, biz, plans[1].$3, '', 'Efectivo', 'total');
    await settle(tester, 3000);
    final t = await detailText(tester, plans[1].$3);
    check(t.contains('Pagada'),
        '${biz.code}: pago total de ${plans[1].$3.first}: Pagada', t);
  }
  await logout(tester);
}

/// Citas a futuro: 1 y varios servicios, horas libres según la duración,
/// choque entre dispositivos y lo que el servidor rechaza.
Future<void> phaseFutureA(WidgetTester tester) async {
  final biz = bizA;
  log('== A: citas a futuro ==');
  final dayX = nextWeekday(biz.today());
  final ana = biz.employees[0];
  final laura = biz.employees[1];
  final valentina = biz.clients[0];
  final camila = biz.clients[1];
  final isabella = biz.clients[2];
  await login(tester, biz.ownerEmail);

  // 1 servicio: Ana, pestañas punto a punto (2 h) a las 10:00.
  var slots = await openAppointmentForm(tester,
      professional: ana.fullName,
      services: ['Pestañas punto a punto'],
      client: isabella,
      day: dayX);
  check(
      slots.isNotEmpty && hm(slots.first) == '09:00',
      'A: Ana día X: la primera hora es la de su horario (09:00)',
      slotsText(slots));
  check(
      slots.isNotEmpty && hm(slots.last) == '16:00',
      'A: Ana día X: la última deja terminar 2 h antes de sus 18:00 (16:00)',
      slotsText(slots));
  final a1 = await chooseSlotAndSave(tester,
      slot: at(dayX, 10), label: 'A_diaX_ana_10');
  check(a1 != null, 'A: cita de 1 servicio (Ana 10:00) agendada');
  await settle(tester);
  var t = await detailText(tester, isabella, shotName: 'A_diaX_ana_detalle');
  check(
      t.contains('10:00') &&
          t.contains('12:00') &&
          t.contains('2 h') &&
          t.contains(cop(150000)),
      'A: Isabella con Ana: 10:00 a. m.-12:00 p. m., 2 h, ${cop(150000)}',
      t);

  // Horas libres por duración: pelo a pelo (2 h 30) con Ana ese día.
  slots = await openAppointmentForm(tester,
      professional: ana.fullName,
      services: ['Pestañas pelo a pelo'],
      client: camila,
      day: dayX);
  await shot(tester, 'A_diaX_ana_horas_150');
  final expected150 = [
    for (var m = 12 * 60; m <= 15 * 60 + 30; m += 15) at(dayX, m ~/ 60, m % 60),
  ];
  check(
      slotsText(slots) == slotsText(expected150),
      'A: Ana 2 h 30 tras su cita de 10-12: solo 12:00…15:30 '
      '(nada que pise 10:00-12:00 ni pase de las 18:00)',
      slotsText(slots));
  await tapText(tester, 'Cancelar', wait: 1000);

  // Varios servicios: Laura 10:00 (misma hora que Ana: otra profesional).
  slots = await openAppointmentForm(tester,
      professional: laura.fullName,
      services: [
        'Cejas semipermanente',
        'Depilación de bozo',
        'Depilación de axilas'
      ],
      client: valentina,
      day: dayX);
  t = allText();
  check(t.contains('${cop(160000)} · 1 h 5 min'),
      'A: formulario de 3 servicios: ${cop(160000)} · 1 h 5 min', t);
  check(
      slots.any((s) => hm(s) == '10:00'),
      'A: Laura libre a las 10:00 aunque Ana tenga cita a esa hora',
      slotsText(slots));
  final a2 = await chooseSlotAndSave(tester,
      slot: at(dayX, 10), label: 'A_diaX_laura_10');
  check(a2 != null, 'A: cita de 3 servicios (Laura 10:00) agendada');
  await settle(tester);
  t = await detailText(tester, valentina, shotName: 'A_diaX_laura_detalle');
  check(
      t.contains('10:00') &&
          t.contains('11:05') &&
          t.contains('1 h 5 min') &&
          t.contains(cop(160000)) &&
          t.contains('Cejas semipermanente') &&
          t.contains('Depilación de bozo') &&
          t.contains('Depilación de axilas'),
      'A: Valentina con Laura: 10:00-11:05, 3 servicios, ${cop(160000)}',
      t);

  // Choque por duración en las horas libres de Laura (diseño, 30 min).
  slots = await openAppointmentForm(tester,
      professional: laura.fullName,
      services: ['Diseño de cejas'],
      client: camila,
      day: dayX);
  await shot(tester, 'A_diaX_laura_horas_30');
  final offered = slots.map(hm).toSet();
  check(
      offered.containsAll(['09:00', '09:15', '09:30', '11:15']) &&
          !offered.any(['09:45', '10:00', '10:30', '11:00'].contains),
      'A: Laura 30 min: libre 9:30 y 11:15; ocupado 9:45-11:00 '
      '(su cita de 10:00 a 11:05)',
      slotsText(slots));

  // Choque entre dispositivos: la app tiene elegidas las 14:00 y, antes de
  // agendar, Laura reserva esa hora desde su teléfono. Con conexión la app
  // crea la cita directo en el servidor (13.05): el 409 vuelve al formulario
  // con su motivo, no se guarda nada y no queda ninguna cita "por mover".
  final hasTwo = slots.any((s) => hm(s) == '14:00');
  final other = OtherDevice();
  var otherBooked = false;
  if (hasTwo && await other.login(tester, laura.email)) {
    await tap(
        tester, find.byKey(ValueKey('slot-${at(dayX, 14).toIso8601String()}')),
        wait: 300);
    final clientId =
        await other.idOf('/clients', (c) => c['phone'] == valentina.phone);
    final serviceId =
        await other.idOf('/services', (s) => s['name'] == 'Diseño de cejas');
    final r = await other.book(
        clientId ?? '', [serviceId ?? ''], instantIn(biz.zone, at(dayX, 14)));
    otherBooked = r.statusCode == 201;
    check(
        otherBooked,
        'A: (otro dispositivo) Laura reserva las 14:00 para Valentina',
        '${r.statusCode} ${r.data}');
    await tap(tester, find.widgetWithText(FilledButton, 'Agendar'), wait: 1500);
    final warned = await waitFor(
        tester, find.text('Ya hay una cita a esa hora'),
        timeout: const Duration(seconds: 15));
    await shot(tester, 'A_choque_aviso');
    t = allText();
    check(
        warned && t.contains(AppointmentFeedback.slotUnavailableTitle),
        'A: choque: al guardar las 14:00 sale "Horario no disponible · Ya hay '
        'una cita a esa hora"',
        t);
    if (find.text('Entendido').evaluate().isNotEmpty) {
      await tap(tester, find.text('Entendido').last, wait: 1500);
    }
    check(find.text('Nueva cita').evaluate().isNotEmpty,
        'A: choque: el formulario sigue abierto (no se guardó)', allText());
    check(find.byKey(const Key('banner-reschedule')).evaluate().isEmpty,
        'A: choque: ninguna cita queda "por mover"', allText());
    // El formulario vuelve a pedir las horas libres: las 14:00 ya no salen.
    await waitFor(tester, find.byType(ChoiceChip));
    await idle(tester, 1000);
    final again = slotTimes();
    check(
        again.isNotEmpty && !again.any((s) => hm(s) == '14:00'),
        'A: choque: las horas libres ya no ofrecen las 14:00',
        slotsText(again));
    final moved = await chooseSlotAndSave(tester,
        slot: at(dayX, 15), label: 'A_choque_otra_hora');
    check(moved != null, 'A: choque: Camila queda agendada a las 15:00');
    await settle(tester);
    check(find.byKey(const Key('banner-reschedule')).evaluate().isEmpty,
        'A: choque: tras sincronizar sigue sin citas "por mover"', allText());
    await showDay(tester, dayX);
    await settle(tester, 4000);
    await shot(tester, 'A_diaX_agenda');
    t = allText();
    check(
        t.contains(valentina.fullName) &&
            t.contains(isabella.fullName) &&
            t.contains(camila.fullName),
        'A: la agenda del día X muestra también la reserva del otro '
        'dispositivo',
        t);
  } else {
    check(
        false,
        'A: preparar el choque (14:00 libre y login del otro '
        'dispositivo)',
        slotsText(slots));
    await tapText(tester, 'Cancelar', wait: 800);
  }

  // Lo que la app no ofrece, el servidor tampoco lo acepta (otro dispositivo).
  if (otherBooked) {
    final clientId =
        await other.idOf('/clients', (c) => c['phone'] == camila.phone);
    final serviceId =
        await other.idOf('/services', (s) => s['name'] == 'Diseño de cejas');
    final yesterday = biz.today().subtract(const Duration(days: 1));
    var r = await other.book(
        clientId!, [serviceId!], instantIn(biz.zone, at(yesterday, 10)));
    check(
        r.statusCode != 201 && '${r.data}'.contains('APPOINTMENT_IN_PAST'),
        'A: (otro dispositivo) cita en el pasado: rechazada',
        '${r.statusCode} ${r.data}');
    r = await other.book(
        clientId, [serviceId], instantIn(biz.zone, at(dayX, 10, 30)));
    check(
        r.statusCode == 409 && '${r.data}'.contains('Horario no disponible'),
        'A: (otro dispositivo) 10:30 pisa su cita de 10:00-11:05: '
            '"Horario no disponible"',
        '${r.statusCode} ${r.data}');
    final pestanas = await other.idOf(
        '/services', (s) => s['name'] == 'Pestañas punto a punto');
    r = await other.book(
        clientId, [pestanas ?? ''], instantIn(biz.zone, at(dayX, 16)));
    check(
        r.statusCode != 201,
        'A: (otro dispositivo) Laura no puede agendar un servicio que no hace',
        '${r.statusCode} ${r.data}');
  }
  await bookFromCalendarCell(tester, biz, dayX, ana, isabella, valentina);
  await phaseHoursA(tester);
  await logout(tester);
}

/// Cita nueva como la agenda la gente: en la vista de día se toca el bloque
/// de una hora libre (aquí, el de las 12:00, justo debajo de la cita de
/// [anchor] de 10:00 a 12:00) y el formulario abre con esa hora ya elegida.
Future<void> bookFromCalendarCell(WidgetTester tester, Biz biz, DateTime day,
    Emp pro, Cli anchor, Cli client) async {
  await showDay(tester, day);
  await idle(tester, 2000);
  final anchorText = find.text(anchor.fullName);
  final block =
      find.ancestor(of: anchorText, matching: find.byType(AppointmentTile));
  if (block.evaluate().isEmpty) {
    check(false, '${biz.code}: la agenda muestra el bloque de ${anchor.first}',
        allText());
    return;
  }
  // Que el final de la cita quede a media pantalla.
  var rect = tester.getRect(block.first);
  final middle =
      tester.view.physicalSize.height / tester.view.devicePixelRatio / 2;
  // Arrastre lento con el dedo sobre la agenda (sin impulso), en tramos.
  final calendar = tester.getRect(find.byType(AppointmentCalendar));
  for (var i = 0; i < 6 && (rect.bottom - middle).abs() > 40; i++) {
    final dy = (middle - rect.bottom).clamp(-300.0, 300.0);
    await tester.timedDragFrom(Offset(calendar.center.dx, calendar.center.dy),
        Offset(0, dy), const Duration(milliseconds: 700));
    await idle(tester, 800);
    rect = tester.getRect(block.first);
  }
  final perMinute = rect.height / 120; // la cita de [anchor] dura 2 h
  final target = Offset(rect.center.dx, rect.bottom + perMinute * 15);
  await shot(tester, '${biz.code}_agenda_antes_de_tocar_12');
  if (watchMode) await idle(tester, 1500);
  await tester.tapAt(target);
  final opened = await waitFor(tester, find.text('Nueva cita'),
      timeout: const Duration(seconds: 10));
  check(
      opened,
      '${biz.code}: tocar la hora 12:00 de la agenda abre "Nueva cita"',
      allText());
  if (!opened) return;
  await idle(tester, 1500);
  final slots = await fillAppointmentForm(tester,
      professional: pro.fullName,
      services: ['Pestañas punto a punto'],
      client: client);
  final noon = at(day, 12);
  final chip = find.byKey(ValueKey('slot-${noon.toIso8601String()}'));
  final preselected =
      chip.evaluate().isNotEmpty && tester.widget<ChoiceChip>(chip).selected;
  await shot(tester, '${biz.code}_cita_desde_bloque_12');
  check(
      preselected,
      '${biz.code}: la hora tocada (12:00) queda elegida en el formulario',
      slotsText(slots));
  final saved = await tap(tester, find.widgetWithText(FilledButton, 'Agendar'),
          wait: 3000)
      .then((_) => waitGone(tester, find.text('Nueva cita'),
          timeout: const Duration(seconds: 10)));
  check(saved, '${biz.code}: cita agendada desde el bloque de las 12:00',
      allText());
  await settle(tester);
  final newBlock = find.ancestor(
      of: find.text(client.fullName), matching: find.byType(AppointmentTile));
  Rect? under;
  for (final e in newBlock.evaluate()) {
    final r = tester.getRect(find.byWidget(e.widget).first);
    if ((r.top - rect.bottom).abs() < 6) under = r;
  }
  await shot(tester, '${biz.code}_agenda_cita_desde_bloque');
  check(
      under != null,
      '${biz.code}: la agenda pinta la cita de ${client.first} justo debajo '
      'de la de ${anchor.first} (12:00)',
      allText());
  if (under == null) return;
  // Tocar el bloque nuevo abre su detalle.
  await tester.tapAt(under.center);
  await idle(tester, 2000);
  final t = allText();
  await shot(tester, '${biz.code}_detalle_cita_desde_bloque');
  await closeDialog(tester);
  check(
      t.contains('12:00') && t.contains('2:00') && t.contains(cop(150000)),
      '${biz.code}: detalle: ${client.first} con ${pro.first} 12:00-2:00 p. m., '
      '${cop(150000)}',
      t);
}

// ───────────────── Horario partido y días cerrados (13.03) ─────────────────

const _weekdayKeys = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

/// Próximo día con [weekday] estrictamente después de [from].
DateTime nextWeekdayOf(DateTime from, int weekday) {
  var d = DateTime(from.year, from.month, from.day + 1);
  while (d.weekday != weekday) {
    d = DateTime(d.year, d.month, d.day + 1);
  }
  return d;
}

/// [e] con dos franjas el día [weekday] (9-12 y 14-18), la segunda con
/// "Añadir franja" (13.06). Al volver a abrir su ficha conserva las dos.
Future<void> splitEmployeeDay(
    WidgetTester tester, Biz biz, Emp e, int weekday) async {
  final label = _dayNames[weekday - 1];
  final dayKey = _weekdayKeys[weekday - 1];
  final start1 = semanticsButton('$label, hora de inicio');
  final end1 = semanticsButton('$label, hora de fin');
  final start2 = semanticsButton('$label, franja 2, inicio');
  final end2 = semanticsButton('$label, franja 2, fin');
  final toggle = find.widgetWithText(SwitchListTile, label);
  final list = find
      .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down)
      .first;

  await openDrawerItem(tester, 'Personal');
  await idle(tester, 1500);
  await openEditEmployee(tester, e);
  await tester.scrollUntilVisible(toggle, 300, scrollable: list);
  await tester.ensureVisible(toggle);
  if (!tester.widget<SwitchListTile>(toggle).value) {
    await tap(tester, toggle, wait: 400);
  }
  if (!_buttonShows(tester, start1, '09:00')) {
    await pickTime(tester, start1, '09:00');
  }
  if (!_buttonShows(tester, end1, '12:00')) {
    await pickTime(tester, end1, '12:00');
  }
  if (start2.evaluate().isEmpty) {
    final add = find.byKey(Key('employee-add-range-$dayKey'));
    check(
        add.evaluate().isNotEmpty,
        '${biz.code}: ${e.first}: botón "Añadir franja" del ${label.toLowerCase()}',
        allText());
    if (add.evaluate().isEmpty) return;
    await tap(tester, add, wait: 600);
  }
  // La franja nueva sale una hora después de la primera (13:00-14:00):
  // primero el fin, para no dejarla al revés por un momento.
  if (!_buttonShows(tester, end2, '18:00')) {
    await pickTime(tester, end2, '18:00');
  }
  if (!_buttonShows(tester, start2, '14:00')) {
    await pickTime(tester, start2, '14:00');
  }
  await shot(tester, '${biz.code}_${e.key}_dos_franjas');
  await tap(tester, find.text('Guardar cambios'), wait: 3000);
  final saved = await waitFor(tester, find.text('Profesionales'),
      timeout: const Duration(seconds: 10));
  check(
      saved,
      '${biz.code}: ${e.first} guarda dos franjas el ${label.toLowerCase()} '
      '(9-12 y 14-18)',
      allText());
  if (!saved) return;
  await idle(tester, 1500);

  // Volver a abrir: siguen las dos (el servidor devuelve `schedule_slots`).
  await openEditEmployee(tester, e);
  await tester.scrollUntilVisible(toggle, 300, scrollable: list);
  await tester.ensureVisible(toggle);
  await idle(tester, 600);
  final kept = _buttonShows(tester, start1, '09:00') &&
      _buttonShows(tester, end1, '12:00') &&
      _buttonShows(tester, start2, '14:00') &&
      _buttonShows(tester, end2, '18:00');
  await shot(tester, '${biz.code}_${e.key}_dos_franjas_reabierta');
  check(
      kept,
      '${biz.code}: al volver a abrir a ${e.first}, el ${label.toLowerCase()} '
      'conserva 9-12 y 14-18',
      allText());
  await back(tester);
  await back(tester);
}

/// Toca en la vista de día la celda de media hora de [hour]:[minute]: lleva
/// esa hora al centro de la columna (el calendario mide 70 px por cada 30
/// min desde su primera hora) y toca a la derecha de la regla de horas.
Future<void> tapAgendaAt(WidgetTester tester, int hour, int minute) async {
  final calendar = find.byType(SfCalendar);
  final settings = tester.widget<SfCalendar>(calendar).timeSlotViewSettings;
  final cell = settings.timeIntervalHeight;
  final perCell = settings.timeInterval.inMinutes;
  final screen =
      Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
  final lists = find.descendant(
      of: calendar,
      matching: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down));
  Finder? list;
  for (var i = 0; i < lists.evaluate().length; i++) {
    final rect = tester.getRect(lists.at(i));
    if (rect.height > 100 && screen.contains(rect.center)) {
      list = lists.at(i);
      break;
    }
  }
  if (list == null) {
    throw StateError('La vista de día no tiene columna de horas en pantalla');
  }
  final position = tester.state<ScrollableState>(list).position;
  final rect = tester.getRect(list);
  final fromStart =
      (hour * 60 + minute - settings.startHour * 60) / perCell * cell;
  position.jumpTo((fromStart + cell / 2 - rect.height / 2)
      .clamp(position.minScrollExtent, position.maxScrollExtent));
  await idle(tester, 800);
  final y = rect.top + fromStart + cell / 2 - position.pixels;
  final x = rect.left +
      AppointmentCalendar.timeRulerSize +
      (rect.width - AppointmentCalendar.timeRulerSize) / 2;
  if (watchMode) await idle(tester, 1200);
  await tester.tapAt(Offset(x, y));
  await idle(tester, 1500);
}

/// Hora de pared (`12:30`) de una hora libre del servidor: viene con el
/// offset del negocio (`…T12:30:00.000-05:00`).
String wallOf(dynamic iso) => '$iso'.substring(11, 16);

/// D-25 y D-26 en A: la agenda del día partido va de corrido (sin "Cerrado"
/// al mediodía) y en la app se agenda el almuerzo; antes de abrir y un día
/// cerrado no abren el formulario; el link público no ofrece ni acepta el
/// almuerzo. Laura tiene dos franjas ese día (no está libre a mediodía).
Future<void> phaseHoursA(WidgetTester tester) async {
  final biz = bizA;
  log('== A: horario partido, fuera de horario y día cerrado ==');
  final split = nextWeekdayOf(biz.today(), splitWeekday);
  final ana = biz.employees[0];
  final laura = biz.employees[1];
  final isabella = biz.clients[2];
  await splitEmployeeDay(tester, biz, laura, splitWeekday);

  // Lo que dice el servidor: horas libres de la app y del link público.
  final owner = OtherDevice();
  if (await owner.login(tester, biz.ownerEmail)) {
    final settings = await owner.dio.get<dynamic>('/settings');
    final slug = settings.data is Map ? '${settings.data['slug']}' : '';
    final anaId =
        await owner.idOf('/auth/employees', (e) => e['email'] == ana.email) ??
            '';
    final serviceId = await owner.idOf(
            '/services', (s) => s['name'] == 'Pestañas punto a punto') ??
        '';
    // El servicio se creó sin "Se puede reservar en línea": el Owner lo
    // publica desde su otro dispositivo para poder preguntarle al link.
    final published = await owner.dio
        .patch<dynamic>('/services/$serviceId', data: {'onlineBooking': true});
    check(
        published.statusCode == 200,
        'A: (otro dispositivo) "Pestañas punto a punto" se reserva en línea',
        '${published.statusCode} ${published.data}');
    final day = '${split.year}-${split.month.toString().padLeft(2, '0')}-'
        '${split.day.toString().padLeft(2, '0')}';
    final query = {
      'professional_id': anaId,
      'date': day,
      'service_ids': serviceId,
      'step': 15,
    };
    final app = await owner.dio
        .get<dynamic>('/appointments/available-slots', queryParameters: query);
    final public = Dio(
        BaseOptions(baseUrl: EnvConfig.apiUrl, validateStatus: (_) => true));
    final web = await public.get<dynamic>(
        '/public/businesses/$slug/available-slots',
        queryParameters: query);
    final appHours = [if (app.data is List) ...(app.data as List).map(wallOf)];
    final webHours = [
      if (web.data is Map && web.data['slots'] is List)
        ...(web.data['slots'] as List).map(wallOf)
    ];
    check(
        appHours.contains('12:30') && appHours.contains('13:00'),
        'A: (API de la app) Ana, 2 h, día partido: ofrece 12:30 y 13:00 '
        '(D-26: el almuerzo no cierra la app)',
        appHours.join(' '));
    check(
        webHours.isNotEmpty &&
            !webHours.any(
                (h) => h.compareTo('10:00') > 0 && h.compareTo('14:00') < 0),
        'A: (link público) Ana, 2 h, día partido: nada entre 10:15 y 13:45 '
        '(el almuerzo está cerrado)',
        webHours.join(' '));
    // El link público limita las reservas por IP (5 por minuto).
    late Response<dynamic> booking;
    for (var attempt = 0; attempt < 3; attempt++) {
      booking = await public
          .post<dynamic>('/public/businesses/$slug/bookings', data: {
        'service_ids': [serviceId],
        'professional_id': anaId,
        'start':
            instantIn(biz.zone, at(split, 12, 30)).toUtc().toIso8601String(),
        'client': {
          'name': 'Web',
          'lastname': 'Almuerzo',
          'phone': phone('320', '01')
        },
      });
      if (booking.statusCode != 429) break;
      await waitThrottle(tester, 'reserva pública');
    }
    check(
        booking.statusCode == 409 &&
            '${booking.data}'.contains('OUTSIDE_BUSINESS_HOURS') &&
            '${booking.data}'.contains('OUTSIDE_OPENING_HOURS'),
        'A: (link público) reservar a las 12:30 del día partido: rechazado '
            '(fuera del horario)',
        '${booking.statusCode} ${booking.data}');
  }

  // La agenda del día partido: de 8 a 19, solo 8:00-8:30 sombreado.
  await showDay(tester, split);
  final calendar = tester.widget<SfCalendar>(find.byType(SfCalendar));
  final range = calendar.timeSlotViewSettings;
  check(
      range.startHour == 8 && range.endHour == 19,
      'A: día partido: la agenda va de 8:00 a 19:00',
      '${range.startHour}-${range.endHour}');
  int minuteOf(DateTime t) => t.hour * 60 + t.minute;
  final shaded = [
    for (final r in calendar.specialRegions ?? const <TimeRegion>[])
      '${hm(r.startTime)}-${hm(r.endTime)}'
  ];
  check(
      !(calendar.specialRegions ?? const <TimeRegion>[]).any((r) =>
          minuteOf(r.startTime) < 14 * 60 && minuteOf(r.endTime) > 12 * 60),
      'A: día partido: el almuerzo no sale "Cerrado" (D-26)',
      shaded);
  check(shaded.length == 1 && shaded.first == '08:00-08:30',
      'A: día partido: solo 8:00-8:30 sombreado (abre a las 8:30)', shaded);
  await shot(tester, 'A_dia_partido_agenda');

  // Antes de abrir: explica y no abre el formulario.
  await tapAgendaAt(tester, 8, 0);
  var t = allText();
  await shot(tester, 'A_dia_partido_antes_de_abrir');
  check(
      t.contains('Fuera del horario') &&
          t.contains('el negocio está cerrado') &&
          t.contains('de ${formatHhmm('08:30')} a ${formatHhmm('19:00')}') &&
          find.text('Nueva cita').evaluate().isEmpty,
      'A: tocar las 8:00 del día partido: "Fuera del horario" con el tramo '
      '8:30 a. m.-7:00 p. m. y sin formulario',
      t);
  if (find.byKey(AgendaSlotSheet.dismissKey).evaluate().isNotEmpty) {
    await tap(tester, find.byKey(AgendaSlotSheet.dismissKey), wait: 800);
  }

  // 12:30 (almuerzo del negocio): abre "Nueva cita" con la hora y una
  // profesional libre (Ana; Laura está en su descanso).
  await tapAgendaAt(tester, 12, 30);
  final opened = await waitFor(tester, find.text('Nueva cita'),
      timeout: const Duration(seconds: 10));
  check(opened, 'A: tocar las 12:30 del día partido abre "Nueva cita"',
      allText());
  if (opened) {
    await idle(tester, 1500);
    final proTile = find.byKey(const Key('appointment-professional'));
    final pro = find
        .descendant(of: proTile, matching: find.byType(Text))
        .evaluate()
        .map((e) => (e.widget as Text).data ?? '')
        .join(' ');
    check(
        pro.contains(ana.fullName),
        'A: a las 12:30 propone a ${ana.first} (libre; ${laura.first} descansa)',
        pro);
    await fillAppointmentForm(tester,
        services: ['Pestañas punto a punto'], client: isabella);
    final chip =
        find.byKey(ValueKey('slot-${at(split, 12, 30).toIso8601String()}'));
    final preselected =
        chip.evaluate().isNotEmpty && tester.widget<ChoiceChip>(chip).selected;
    await shot(tester, 'A_dia_partido_1230');
    check(preselected, 'A: la hora tocada (12:30) queda elegida',
        slotsText(slotTimes()));
    if (preselected) {
      await tap(tester, find.widgetWithText(FilledButton, 'Agendar'),
          wait: 3000);
    }
    final saved = preselected &&
        await waitGone(tester, find.text('Nueva cita'),
            timeout: const Duration(seconds: 10));
    check(
        saved,
        'A: cita en el almuerzo del negocio (12:30-14:30 con Ana) guardada',
        allText());
    if (!saved && find.text('Nueva cita').evaluate().isNotEmpty) {
      await dismissDialogs(tester);
      await tapText(tester, 'Cancelar', wait: 1000);
    }
    await settle(tester);
    await showDay(tester, split);
    check(
        allText().contains(isabella.fullName),
        'A: la agenda del día partido muestra la cita de ${isabella.first}',
        allText());
    await shot(tester, 'A_dia_partido_con_cita');
  }

  // Día cerrado: aviso arriba y tocar no abre el formulario.
  final sunday = nextWeekdayOf(biz.today(), DateTime.sunday);
  await showDay(tester, sunday);
  final notice = find.byKey(AgendaDayNotice.closedKey);
  t = allText();
  await shot(tester, 'A_domingo_cerrado');
  check(notice.evaluate().isNotEmpty && t.contains('el negocio está cerrado'),
      'A: domingo: aviso "…el negocio está cerrado"', t);
  await tapAgendaAt(tester, 10, 0);
  t = allText();
  await shot(tester, 'A_domingo_toque');
  check(t.contains('Día cerrado') && find.text('Nueva cita').evaluate().isEmpty,
      'A: tocar el domingo explica "Día cerrado" y no abre el formulario', t);
  if (find.byKey(AgendaSlotSheet.dismissKey).evaluate().isNotEmpty) {
    await tap(tester, find.byKey(AgendaSlotSheet.dismissKey), wait: 800);
  }
}

/// Mi negocio, como lo hace el dueño (pedido del 2026-11-04): el lunes de
/// 8:00 a. m. a 12:00 p. m. y de 2:00 p. m. a 7:00 p. m. Primero se equivoca
/// con "12 a. m." (medianoche): el aviso sale al momento con la corrección, y
/// "Guardar horario" (en la barra de abajo) no deja guardar hasta corregir.
/// Después, el color: con uno propio en Apariencia, Mi negocio lo explica.
Future<void> phaseLunchA(WidgetTester tester) async {
  final biz = bizA;
  log('== A: lunes con almuerzo (8–12 y 2–7) y color del negocio ==');
  await openDrawerItem(tester, 'Mi negocio');
  final limit = find.byKey(const Key('opening-hours-enabled'));
  await waitFor(tester, limit);
  await idle(tester, 1200);
  if (!tester.widget<SwitchListTile>(limit).value) await tap(tester, limit);
  final monday = find.byKey(const Key('opening-day-1'));
  if (!tester.widget<Switch>(monday).value) await tap(tester, monday, wait: 400);
  final remove = find.byTooltip('Quitar franja del Lunes');
  while (remove.evaluate().length > 1) {
    await tap(tester, remove.last, wait: 300);
  }
  final open1 = semanticsButton('Lunes, franja 1, apertura');
  final close1 = semanticsButton('Lunes, franja 1, cierre');
  final open2 = semanticsButton('Lunes, franja 2, apertura');
  final close2 = semanticsButton('Lunes, franja 2, cierre');
  // De corrido de 8:00 a. m. a 7:00 p. m. y luego "Añadir franja".
  if (!_buttonShows(tester, open1, '08:00')) {
    await pickTime(tester, open1, '08:00');
  }
  if (!_buttonShows(tester, close1, '19:00')) {
    await pickTime(tester, close1, '19:00');
  }
  final save = find.widgetWithText(FilledButton, 'Guardar horario');
  if (save.evaluate().isNotEmpty) {
    await tap(tester, save, wait: 2500);
  }
  await tap(tester, find.byKey(const Key('opening-add-1')), wait: 800);
  check(
      _buttonShows(tester, close1, '12:00') &&
          _buttonShows(tester, open2, '14:00') &&
          _buttonShows(tester, close2, '19:00'),
      'A: "Añadir franja" parte el lunes en 8:00 a. m.–12:00 p. m. y '
      '2:00 p. m.–7:00 p. m.',
      allText());
  check(allText().contains('12:00\u00a0p.\u00a0m. (mediodía)'),
      'A: el cierre de la mañana dice "12:00 p. m. (mediodía)"', allText());
  check(allText().contains('El horario tiene cambios sin guardar.'),
      'A: la barra de abajo avisa que falta guardar', allText());
  await shot(tester, 'A_lunes_partido_sin_guardar');

  // El error del dueño: "cierra a las 12 a. m.".
  await pickTime(tester, close1, '00:00');
  final problem = find.byKey(const Key('opening-backwards-1-0'));
  await waitFor(tester, problem);
  check(
      problem.evaluate().isNotEmpty &&
          allText().contains('¿Querías decir 12:00\u00a0p.\u00a0m. (mediodía)?'),
      'A: "12 a. m." avisa al momento: cierra antes de abrir, ¿querías '
      'decir 12:00 p. m. (mediodía)?',
      allText());
  check(
      tester.widget<FilledButton>(save).onPressed == null &&
          allText().contains('Corrige lo que está en rojo para guardar.'),
      'A: con el error no deja guardar y lo dice',
      allText());
  await shot(tester, 'A_lunes_12am_aviso');
  await tap(tester, find.byKey(const Key('opening-backwards-1-0-fix')),
      wait: 800);
  check(problem.evaluate().isEmpty && _buttonShows(tester, close1, '12:00'),
      'A: "Cerrar a las 12:00 p. m." lo corrige con un toque', allText());
  await tap(tester, save, wait: 2500);
  check(
      find.byKey(const Key('opening-hours-unsaved')).evaluate().isEmpty,
      'A: horario del lunes guardado (la barra se va)',
      allText());
  await shot(tester, 'A_lunes_guardado');
  await back(tester);

  // Al volver a entrar sigue igual: se guardó en el servidor.
  await openDrawerItem(tester, 'Mi negocio');
  await waitFor(tester, limit);
  await idle(tester, 1500);
  check(
      _buttonShows(tester, open1, '08:00') &&
          _buttonShows(tester, close1, '12:00') &&
          _buttonShows(tester, open2, '14:00') &&
          _buttonShows(tester, close2, '19:00'),
      'A: al volver a Mi negocio el lunes sigue 8–12 y 2–7',
      allText());
  await back(tester);

  // Color: uno propio en este teléfono (Apariencia) frente al del negocio.
  await openDrawerItem(tester, 'Apariencia');
  await idle(tester, 1200);
  await tap(tester, find.byKey(const Key('palette-azul')), wait: 1200);
  await shot(tester, 'A_apariencia_azul');
  await back(tester);
  await openDrawerItem(tester, 'Mi negocio');
  final note = find.byKey(const Key('palette-own-device-note'));
  await waitFor(tester, find.byKey(const Key('business-name')));
  await idle(tester, 1200);
  await centerOn(tester, find.text('Color del negocio'));
  await idle(tester, 800);
  check(note.evaluate().isNotEmpty,
      'A: Mi negocio explica que este teléfono usa su propio color', allText());
  await shot(tester, 'A_color_propio_nota');
  await tap(tester, find.byKey(const Key('palette-use-business-here')),
      wait: 1500);
  check(note.evaluate().isEmpty,
      'A: "Ver aquí el del negocio" vuelve al color del negocio', allText());
  await shot(tester, 'A_color_del_negocio');
  await back(tester);
  log('${biz.code}: lunes con almuerzo y color revisados');
}

Future<void> phaseFutureB(WidgetTester tester) async {
  final biz = bizB;
  log('== B: citas a futuro y aislamiento ==');
  final dayX = nextWeekday(biz.today());
  final sofia = biz.employees[0];
  final maria = biz.clients[0];
  final gabriela = biz.clients[1];
  await login(tester, biz.ownerEmail);
  check(allText().contains('Horas en la zona del negocio'),
      'B: la agenda avisa que las horas van en America/Caracas', allText());

  // Misma hora local que Ana y Laura en Bogotá: Sofía libre.
  var slots = await openAppointmentForm(tester,
      professional: sofia.fullName,
      services: ['Manicure', 'Pedicure'],
      client: gabriela,
      day: dayX);
  var t = allText();
  check(t.contains('${cop(70000)} · 1 h 45 min'),
      'B: manicure + pedicure: ${cop(70000)} · 1 h 45 min', t);
  check(
      slots.isNotEmpty &&
          hm(slots.first) == '09:00' &&
          hm(slots.last) == '16:15',
      'B: Sofía de 9:00 a 16:15 (termina a las 18:00 de Caracas)',
      slotsText(slots));
  check(
      slots.any((s) => hm(s) == '10:00'),
      'B: las 10:00 de Caracas libres aunque A tenga citas a las 10:00 de '
      'Bogotá',
      slotsText(slots));
  await chooseSlotAndSave(tester, slot: at(dayX, 10), label: 'B_diaX_10');
  await settle(tester);
  t = await detailText(tester, gabriela, shotName: 'B_diaX_detalle');
  check(t.contains('10:00') && t.contains('11:45') && t.contains(cop(70000)),
      'B: Gabriela 10:00-11:45 en hora de Caracas (el Mac está en Bogotá)', t);

  // 1 servicio con el nombre que también existe en A.
  slots = await openAppointmentForm(tester,
      professional: sofia.fullName,
      services: ['Diseño de cejas'],
      client: maria,
      day: dayX);
  check(t.isNotEmpty && allText().contains(cop(25000)),
      'B: "Diseño de cejas" de B cuesta ${cop(25000)} (no el de A)', allText());
  await chooseSlotAndSave(tester, slot: at(dayX, 14), label: 'B_diaX_14');
  await settle(tester);

  // Fuera del horario del negocio: Sofía trabaja el sábado, B no abre. Si
  // hoy es sábado, la fase de hoy lo abrió entero: se usa el domingo.
  final saturday = biz.today().weekday == DateTime.saturday
      ? nextSaturday(biz.today()).add(const Duration(days: 1))
      : nextSaturday(biz.today());
  slots = await openAppointmentForm(tester,
      professional: sofia.fullName,
      services: ['Manicure'],
      client: maria,
      day: saturday);
  await shot(tester, 'B_sabado_cerrado');
  check(
      slots.isEmpty && allText().contains('No hay horas libres'),
      'B: sábado (negocio cerrado) sin horas aunque Sofía trabaje',
      slotsText(slots));
  await tapText(tester, 'Cancelar', wait: 800);
  final other = OtherDevice();
  if (await other.login(tester, sofia.email)) {
    final clientId =
        await other.idOf('/clients', (c) => c['phone'] == maria.phone);
    final serviceId =
        await other.idOf('/services', (s) => s['name'] == 'Manicure');
    final r = await other.book(clientId ?? '', [serviceId ?? ''],
        instantIn(biz.zone, at(saturday, 10)));
    check(
        r.statusCode != 201 && '${r.data}'.contains('OUTSIDE_BUSINESS_HOURS'),
        'B: (otro dispositivo) sábado 10:00: fuera del horario del negocio',
        '${r.statusCode} ${r.data}');
    final services = await other.dio.get<dynamic>('/services');
    final names = [
      for (final s in (services.data is List ? services.data as List : []))
        if (s is Map) '${s['name']}'
    ];
    check(
        !names.contains('Pestañas punto a punto') && names.length == 5,
        'B: (otro dispositivo) el API de B solo devuelve sus 5 servicios',
        names);
  }

  // Aislamiento en la app con datos de los dos negocios.
  await showDay(tester, dayX);
  await shot(tester, 'B_diaX_agenda');
  t = allText();
  check(
      !bizA.clients.any((c) => t.contains(c.fullName)) &&
          t.contains(gabriela.fullName),
      'B: la agenda del día X solo tiene citas de B',
      t);
  await openDrawerItem(tester, 'Clientela');
  await idle(tester, 2000);
  await shot(tester, 'B_clientes');
  t = allText();
  check(t.contains(maria.fullName) && !t.contains('Valentina'),
      'B: con el mismo teléfono que Valentina (A), B ve a su María', t);
  await back(tester);
  await openDrawerItem(tester, 'Servicios');
  await idle(tester, 2000);
  t = allText();
  check(
      biz.services.every((s) => t.contains(s.name)) &&
          ![
            'Pestañas punto a punto',
            'Cejas semipermanente',
            'Depilación de bozo'
          ].any(t.contains) &&
          t.contains(cop(25000)) &&
          !t.contains(cop(35000)),
      'B: catálogo solo de B ("Diseño de cejas" a ${cop(25000)})',
      t);
  await back(tester);
  await openDrawerItem(tester, 'Personal');
  await idle(tester, 2000);
  t = allText();
  check(
      t.contains(sofia.fullName) &&
          !t.contains('Ana Gómez') &&
          !t.contains('Laura Pérez'),
      'B: solo Sofía en Personal',
      t);
  await back(tester);
  await logout(tester);
}

/// Espera a que empiecen las citas de hoy y las completa.
Future<void> completeToday(WidgetTester tester, Biz biz) async {
  final today = biz.today();
  await showDay(tester, today);
  final agenda = Get.find<AppointmentsController>();
  final mine = agenda.appointments
      .where((a) => !a.isCancelled && !a.isCompleted)
      .toList();
  if (mine.isEmpty) {
    skip('${biz.code}: completar citas de hoy', 'no hay citas de hoy');
    return;
  }
  final last =
      mine.map((a) => a.startTime).reduce((a, b) => a.isAfter(b) ? a : b);
  final wait = last.difference(biz.now()) + const Duration(seconds: 20);
  if (wait > Duration.zero) {
    if (wait > const Duration(minutes: 25)) {
      skip('${biz.code}: completar citas de hoy',
          'la última empieza a las ${hm(last)} (falta mucho)');
      return;
    }
    log('${biz.code}: esperando ${wait.inSeconds} s a que empiecen las citas');
    await idle(tester, wait.inMilliseconds);
    await showDay(tester, today);
  }
  for (final a in mine) {
    final name = a.clientName;
    if (!await openDetail(tester, name)) {
      check(false, '${biz.code}: abrir la cita de hoy de $name', allText());
      continue;
    }
    final button = find.widgetWithText(OutlinedButton, 'Completar');
    if (button.evaluate().isEmpty) {
      check(
          false, '${biz.code}: botón Completar en la cita de $name', allText());
      await closeDialog(tester);
      continue;
    }
    await tap(tester, button, wait: 1200);
    await tap(tester, find.widgetWithText(FilledButton, 'Completar'),
        wait: 3000);
    await settle(tester, 3000);
    final t = await detailText(tester,
        Cli(name.split(' ').first, name.split(' ').skip(1).join(' '), ''),
        shotName: '${biz.code}_completada_${name.split(' ').first}');
    check(t.contains('Completada'), '${biz.code}: cita de $name completada', t);
  }
}

Future<void> checkCommissions(WidgetTester tester, Biz biz,
    {required Map<String, (int, int)> perPro}) async {
  await openDrawerItem(tester, 'Comisiones');
  await idle(tester, 4000);
  await shot(tester, '${biz.code}_comisiones');
  var t = allText();
  final services = perPro.values.fold<int>(0, (s, v) => s + v.$1);
  final pro = perPro.values.fold<int>(0, (s, v) => s + v.$2);
  check(
      t.contains(cop(services)) &&
          t.contains(cop(pro)) &&
          t.contains(cop(services - pro)),
      '${biz.code}: total del período: servicios ${cop(services)}, '
      'profesionales ${cop(pro)}, negocio ${cop(services - pro)}',
      t);
  for (final entry in perPro.entries) {
    check(
        t.contains(entry.key) && t.contains(cop(entry.value.$2)),
        '${biz.code}: ${entry.key}: ${cop(entry.value.$1)} → '
        '${cop(entry.value.$2)}',
        t);
  }
  for (final other in [bizA, bizB].where((b) => b != biz)) {
    check(!other.employees.any((e) => t.contains(e.fullName)),
        '${biz.code}: comisiones sin profesionales del otro negocio', t);
  }
  if (biz == bizA && t.contains('Laura Pérez')) {
    await tap(tester, find.text('Laura Pérez'), wait: 1500);
    await shot(tester, 'A_comisiones_laura');
    t = allText();
    check(
        t.contains('Cejas semipermanente: ${cop(120000)} × 60') &&
            t.contains(cop(72000)) &&
            t.contains('Depilación de bozo: ${cop(15000)} × 50') &&
            t.contains('Depilación de axilas: ${cop(25000)} × 50'),
        'A: Laura: excepción 60 % en cejas semipermanente y 50 % en el resto',
        t);
  }
  await back(tester);
}

Future<void> checkStats(
    WidgetTester tester, Biz biz, int income, int payments) async {
  await openDrawerItem(tester, 'Informes');
  await idle(tester, 4000);
  await shot(tester, '${biz.code}_estadisticas');
  final t = allText();
  dump('${biz.code} estadísticas');
  check(t.contains(cop(income)),
      '${biz.code}: ingresos de hoy = ${cop(income)} (solo sus pagos)', t);
  check(t.contains('$payments'), '${biz.code}: $payments pagos registrados hoy',
      t);
  await back(tester);
}

Future<void> phaseComplete(WidgetTester tester, Biz biz) async {
  log('== ${biz.code}: completar, comisiones, estadísticas ==');
  await login(tester, biz.ownerEmail);
  await completeToday(tester, biz);
  await settle(tester, 4000);
  final today = biz.today();
  await showDay(tester, today);
  final completed = Get.find<AppointmentsController>()
      .appointments
      .where((a) => a.isCompleted)
      .map((a) => a.professionalName ?? '')
      .toSet();
  if (biz == bizA) {
    await checkCommissions(tester, biz, perPro: {
      if (completed.contains('Laura Pérez')) 'Laura Pérez': (160000, 92000),
      if (completed.contains('Ana Gómez')) 'Ana Gómez': (150000, 45000),
    });
    await checkStats(
        tester,
        biz,
        completed.contains('Ana Gómez') ? 310000 : 160000,
        completed.contains('Ana Gómez') ? 4 : 3);
  } else if (completed.isEmpty) {
    skip('B: comisiones e ingresos de hoy', 'no hubo citas de hoy');
  } else {
    await checkCommissions(tester, biz,
        perPro: {'Sofía Rangel': (30000, 12000)});
    await checkStats(tester, biz, 30000, 2);
  }
  // A, después de crear B: su catálogo sigue sin nada de B.
  if (biz == bizA) {
    await openDrawerItem(tester, 'Servicios');
    await idle(tester, 2000);
    final t = allText();
    check(!t.contains('Manicure') && !t.contains('Pedicure'),
        'A: el catálogo de A no muestra servicios de B', t);
    await back(tester);
  }
  await restoreToday(tester, biz);
  await logout(tester);
}

Future<void> phaseEmployee(WidgetTester tester, Biz biz, Emp e,
    {required List<Cli> sees, required List<Cli> hidden}) async {
  log('== ${biz.code}: sesión de ${e.first} ==');
  await login(tester, e.email);
  await shot(tester, '${biz.code}_${e.key}_agenda');
  final dayX = nextWeekday(biz.today());
  await showDay(tester, dayX);
  await shot(tester, '${biz.code}_${e.key}_diaX');
  var t = allText();
  check(sees.every((c) => t.contains(c.fullName)),
      '${biz.code}: ${e.first} ve sus citas del día X', t);
  check(!hidden.any((c) => t.contains(c.fullName)),
      '${biz.code}: ${e.first} no ve las citas de otras profesionales', t);
  if (sees.isNotEmpty && await openDetail(tester, sees.first.fullName)) {
    t = allText();
    await shot(tester, '${biz.code}_${e.key}_detalle');
    check(
        !t.contains('Editar') &&
            !t.contains('Registrar pago') &&
            !t.contains('Cobrar saldo'),
        '${biz.code}: ${e.first} no edita ni cobra',
        t);
    await closeDialog(tester);
  }
  await tap(tester, find.byType(DrawerButton));
  t = allText();
  await shot(tester, '${biz.code}_${e.key}_menu');
  check(!t.contains('Personal') && !t.contains('Mi negocio'),
      '${biz.code}: menú de ${e.first} sin opciones de Owner', t);
  Navigator.of(tester.element(find.byType(Drawer))).pop();
  await idle(tester, 800);

  await openDrawerItem(tester, 'Comisiones');
  await idle(tester, 4000);
  await shot(tester, '${biz.code}_${e.key}_comisiones');
  t = allText();
  final others = [...bizA.employees, ...bizB.employees].where((o) => o != e);
  check(
      t.contains('Mis comisiones') &&
          !others.any((o) => t.contains(o.fullName)),
      '${biz.code}: ${e.first} ve solo sus comisiones',
      t);
  await back(tester);

  // Cita nueva: el profesional es ella y no se puede cambiar.
  final dayY = nextWeekday(dayX);
  final client = biz.clients[1];
  final service = e.services.last;
  final slots = await openAppointmentForm(tester,
      services: [service], client: client, day: dayY);
  final proTile = find.byKey(const Key('appointment-professional'));
  t = allText();
  check(
      t.contains(e.first) &&
          tester
                  .widget<ListTile>(find
                      .descendant(of: proTile, matching: find.byType(ListTile))
                      .first)
                  .onTap ==
              null,
      '${biz.code}: ${e.first} agenda solo para sí (profesional fijo)',
      t);
  final saved = await chooseSlotAndSave(tester,
      slot: slots.isEmpty ? null : slots[slots.length ~/ 2],
      label: '${biz.code}_${e.key}_cita_propia');
  await settle(tester);
  check(
      saved != null && allText().contains(client.fullName),
      '${biz.code}: ${e.first} creó su cita (${client.first}, $service)',
      allText());
  await logout(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dos negocios desde cero (Bogotá y Caracas)', (tester) async {
    final restoreErrors = await startApp(tester);
    log('RUN=$run  PHASES=$_phases');
    log('A hoy ${bizA.today()} (${hm(bizA.now())}) · B hoy ${bizB.today()} '
        '(${hm(bizB.now())})');
    await shot(tester, 'login');

    if (want('a_setup')) await phaseSetup(tester, bizA);
    if (want('a_today')) await phaseToday(tester, bizA);
    if (want('b_setup')) await phaseSetup(tester, bizB);
    if (want('b_today')) await phaseToday(tester, bizB);
    if (want('a_future')) await phaseFutureA(tester);
    // Solo el paso de la agenda, para repetirlo sobre una corrida hecha; en
    // la corrida completa ya lo hace `a_future` (si no, pediría las 12:00
    // otra vez, ya ocupadas).
    if (_phases != 'all' && want('a_calendar')) {
      await login(tester, bizA.ownerEmail);
      await bookFromCalendarCell(tester, bizA, nextWeekday(bizA.today()),
          bizA.employees[0], bizA.clients[2], bizA.clients[0]);
      await logout(tester);
    }
    // Solo el horario partido y los días cerrados (13.03), para repetirlo
    // sobre una corrida hecha; en la corrida completa lo hace `a_future`.
    if (_phases != 'all' && want('a_hours')) {
      await login(tester, bizA.ownerEmail);
      await phaseHoursA(tester);
      await logout(tester);
    }
    if (_phases != 'all' && want('a_lunch')) {
      await login(tester, bizA.ownerEmail);
      await phaseLunchA(tester);
      await logout(tester);
    }
    if (want('b_future')) await phaseFutureB(tester);
    if (want('a_complete')) await phaseComplete(tester, bizA);
    if (want('a_employee')) {
      await phaseEmployee(tester, bizA, bizA.employees[1],
          sees: [bizA.clients[0], bizA.clients[1]], hidden: [bizA.clients[2]]);
    }
    if (want('b_complete')) await phaseComplete(tester, bizB);
    if (want('b_employee')) {
      await phaseEmployee(tester, bizB, bizB.employees[0],
          sees: [bizB.clients[1]], hidden: bizA.clients);
    }

    log('RUN=$run');
    restoreErrors();
    finish();
  }, timeout: const Timeout(Duration(minutes: 120)));
}
