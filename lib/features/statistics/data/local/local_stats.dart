import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/json_read.dart';

/// Datos locales que necesitan las estadísticas (forma de la API).
class LocalStatsData {
  /// Feed `payments` (solo Owner).
  final List<Map<String, dynamic>> payments;

  /// Feed `appointments`, por id.
  final Map<String, Map<String, dynamic>> appointments;

  /// Nombre y apellido de cada cliente (tabla local de clientes), por id.
  final Map<String, ({String name, String lastname})> clients;

  /// Feed `users`, por id.
  final Map<String, Map<String, dynamic>> users;

  /// Feed `custom_payment_methods`, por id.
  final Map<String, Map<String, dynamic>> customMethods;

  /// Feed `user_services` (para la comisión si la línea no la trae).
  final List<Map<String, dynamic>> userServices;

  const LocalStatsData({
    this.payments = const [],
    this.appointments = const {},
    this.clients = const {},
    this.users = const {},
    this.customMethods = const {},
    this.userServices = const [],
  });
}

/// Estadísticas y liquidación de comisiones calculadas **en la app**
/// (10.02c, D-18) con las mismas cuentas que el backend
/// (`payment-stats.service.ts`, `appointment-commission.ts`). Devuelven el
/// mismo JSON que la API para que lo lean los mismos modelos. Con conexión
/// manda el servidor; esto es para cuando no la hay.
///
/// - Periodo: días completos del negocio, [00:00 del inicio, 23:59:59.999
///   del fin], en su zona actual.
/// - Ingresos: pagos `COMPLETED` netos (`amount − refund_amount`) por su
///   `created_at`. Como el backend, los pagos en revisión también cuentan
///   aquí.
/// - Comisiones: citas `COMPLETED` por su fecha, con el precio y el %
///   guardados en cada línea, en centavos.
class LocalStats {
  final LocalStatsData data;

  const LocalStats(this.data);

  // ------------------------------------------------------------- Periodos

  static ({DateTime start, DateTime end}) window(DateTime from, DateTime to) {
    final start =
        BusinessTimeZone.toInstant(DateTime(from.year, from.month, from.day));
    final end = BusinessTimeZone.toInstant(
            DateTime(to.year, to.month, to.day + 1))
        .subtract(const Duration(milliseconds: 1));
    return (start: start, end: end);
  }

  static bool _within(DateTime? instant, ({DateTime start, DateTime end}) w) =>
      instant != null && !instant.isBefore(w.start) && !instant.isAfter(w.end);

  static DateTime? _instant(Object? value) => value is String
      ? DateTime.tryParse(value.trim())
      : value is DateTime
          ? value
          : null;

  static int _cents(Object? value) => (JsonRead.asDouble(value) * 100).round();

  static double _money(int cents) => cents / 100;

  /// Pagos COMPLETED del periodo (opcionalmente de un profesional).
  List<Map<String, dynamic>> _paid(({DateTime start, DateTime end}) w,
      {String? professionalId}) {
    return [
      for (final p in data.payments)
        if (p['status'] == 'COMPLETED' &&
            _within(_instant(p['created_at']), w) &&
            (professionalId == null ||
                data.appointments[_appointmentId(p)]?['professionalId'] ==
                    professionalId))
          p,
    ];
  }

  static String? _appointmentId(Map<String, dynamic> payment) =>
      JsonRead.asOptionalString(payment['appointment_id']) ??
      (payment['appointment'] is Map
          ? JsonRead.asOptionalString((payment['appointment'] as Map)['id'])
          : JsonRead.asOptionalString(payment['appointment']));

  static int _net(Map<String, dynamic> p) =>
      _cents(p['amount']) - _cents(p['refund_amount']);

  // --------------------------------------------------------------- Totales

  /// `GET /payments/stats`.
  Map<String, dynamic> paymentStats(DateTime from, DateTime to) =>
      _stats(window(from, to));

  Map<String, dynamic> _stats(({DateTime start, DateTime end}) w) {
    final paid = _paid(w);
    final total = paid.fold<int>(0, (s, p) => s + _net(p));
    return {
      'total_amount': _money(total),
      'payment_count': paid.length,
      'average_amount': paid.isEmpty ? 0 : _money(total) / paid.length,
    };
  }

  /// `GET /payments/stats/comparison`.
  Map<String, dynamic> comparison(DateTime from, DateTime to) {
    final current = window(from, to);
    final duration = current.end.difference(current.start);
    final previousEnd =
        current.start.subtract(const Duration(milliseconds: 1));
    final previous = (start: previousEnd.subtract(duration), end: previousEnd);
    final now = _stats(current);
    final before = _stats(previous);
    double n(Map<String, dynamic> m, String k) => (m[k] as num).toDouble();
    Map<String, dynamic> period(
            ({DateTime start, DateTime end}) w, Map<String, dynamic> stats) =>
        {
          'start_date': _day(w.start),
          'end_date': _day(w.end),
          ...stats,
        };
    return {
      'current_period': period(current, now),
      'previous_period': period(previous, before),
      'change': {
        'amount_difference':
            n(now, 'total_amount') - n(before, 'total_amount'),
        'amount_percentage':
            _round2(_percentChange(n(now, 'total_amount'), n(before, 'total_amount'))),
        'count_difference':
            (now['payment_count'] as int) - (before['payment_count'] as int),
        'count_percentage': _round2(_percentChange(
            n(now, 'payment_count'), n(before, 'payment_count'))),
        'average_difference':
            n(now, 'average_amount') - n(before, 'average_amount'),
        'average_percentage': _round2(_percentChange(
            n(now, 'average_amount'), n(before, 'average_amount'))),
      },
    };
  }

  /// Día del negocio de un instante (`yyyy-MM-dd`).
  static String _day(DateTime instant) =>
      DateCodec.encodeDay(BusinessTimeZone.toWallClock(instant));

  /// `percentChange`: `null` si el anterior es 0 (7.04-8).
  static double? _percentChange(double current, double previous) =>
      previous == 0 ? null : (current - previous) * 100 / previous;

  static double? _round2(double? value) =>
      value == null ? null : double.parse(value.toStringAsFixed(2));

  // ------------------------------------------------------------ Por método

  /// `GET /payments/stats/by-method`.
  List<Map<String, dynamic>> byMethod(DateTime from, DateTime to) {
    final groups = <String, Map<String, dynamic>>{};
    for (final p in _paid(window(from, to))) {
      final customId = JsonRead.asOptionalString(p['custom_payment_method_id']);
      final method = customId != null
          ? JsonRead.asOptionalString(data.customMethods[customId]?['name']) ??
              'Método propio'
          : JsonRead.asOptionalString(p['payment_method']) ?? 'SIN_METODO';
      final type = customId != null ? 'CUSTOM' : 'STANDARD';
      final group = groups.putIfAbsent('$method|$type|$customId', () => {
            'method': method,
            'method_type': type,
            'custom_payment_method_id': customId,
            'count': 0,
            'cents': 0,
          });
      group['count'] = (group['count'] as int) + 1;
      group['cents'] = (group['cents'] as int) + _net(p);
    }
    final grand = groups.values.fold<int>(0, (s, g) => s + (g['cents'] as int));
    final rows = [
      for (final g in groups.values)
        {
          'method': g['method'],
          'method_type': g['method_type'],
          'custom_payment_method_id': g['custom_payment_method_id'],
          'count': g['count'],
          'total': _money(g['cents'] as int),
          'average': _money(g['cents'] as int) / (g['count'] as int),
          'percentage':
              grand > 0 ? (g['cents'] as int) * 100 / grand : 0,
        },
    ];
    return rows
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
  }

  // ----------------------------------------------------------- Por servicio

  /// `serviceRevenue` del backend: lo pagado neto de cada cita se reparte
  /// entre sus servicios por el precio guardado en la cita (a partes iguales
  /// si todos valen 0).
  List<Map<String, dynamic>> _serviceRevenue(
      ({DateTime start, DateTime end}) w,
      {String? professionalId}) {
    final perAppointment = <String, ({int net, int payments})>{};
    for (final p in _paid(w, professionalId: professionalId)) {
      final id = _appointmentId(p);
      if (id == null || !data.appointments.containsKey(id)) continue;
      final prev = perAppointment[id] ?? (net: 0, payments: 0);
      perAppointment[id] =
          (net: prev.net + _net(p), payments: prev.payments + 1);
    }
    final services = <String, Map<String, dynamic>>{};
    for (final MapEntry(key: id, value: paid) in perAppointment.entries) {
      final lines = JsonRead.asMapList(data.appointments[id]!['services']);
      final prices = [
        for (final l in lines)
          JsonRead.asDouble(l['appointment_price'] ?? l['price'])
      ];
      final sum = prices.fold<double>(0, (s, p) => s + p);
      for (final (i, line) in lines.indexed) {
        final serviceId = JsonRead.asString(line['id']);
        final share = sum > 0 ? prices[i] / sum : 1 / lines.length;
        final row = services.putIfAbsent(serviceId, () => {
              'service_id': serviceId,
              'service_name': JsonRead.asString(line['name']),
              'appointments': <String>{},
              'payment_count': 0,
              'amount': 0.0,
            });
        (row['appointments'] as Set<String>).add(id);
        row['payment_count'] = (row['payment_count'] as int) + paid.payments;
        row['amount'] = (row['amount'] as double) + paid.net / 100 * share;
      }
    }
    return [
      for (final row in services.values)
        {
          'service_id': row['service_id'],
          'service_name': row['service_name'],
          'appointment_count': (row['appointments'] as Set).length,
          'payment_count': row['payment_count'],
          'total_amount': ((row['amount'] as double) * 100).round() / 100,
        },
    ]..sort((a, b) =>
        (b['total_amount'] as double).compareTo(a['total_amount'] as double));
  }

  /// `GET /payments/stats/by-service`.
  List<Map<String, dynamic>> byService(DateTime from, DateTime to) {
    final rows = _serviceRevenue(window(from, to));
    final grand = rows.fold<double>(0, (s, r) => s + (r['total_amount'] as double));
    return [
      for (final r in rows)
        {
          ...r,
          'average_amount': (r['appointment_count'] as int) > 0
              ? (r['total_amount'] as double) / (r['appointment_count'] as int)
              : 0,
          'percentage_of_total':
              grand > 0 ? (r['total_amount'] as double) * 100 / grand : 0,
        },
    ];
  }

  // -------------------------------------------------------- Por profesional

  /// `CONCAT(name, ' ', COALESCE(lastname, ''))` (deja el espacio).
  static String _concat(Object? name, Object? lastname) =>
      '${JsonRead.asString(name)} ${JsonRead.asString(lastname)}';

  /// `GET /payments/stats/by-professional`.
  List<Map<String, dynamic>> byProfessional(DateTime from, DateTime to) {
    final w = window(from, to);
    final paid = _paid(w);
    if (paid.isEmpty) return const [];
    final total = paid.fold<int>(0, (s, p) => s + _net(p));
    final groups = <String, Map<String, dynamic>>{};
    for (final p in paid) {
      final appointment = data.appointments[_appointmentId(p)];
      final professionalId =
          JsonRead.asOptionalString(appointment?['professionalId']);
      if (professionalId == null) continue;
      final user = data.users[professionalId] ??
          JsonRead.asMap(appointment?['professional']) ??
          const {};
      final g = groups.putIfAbsent(professionalId, () => {
            'professional_id': professionalId,
            'professional_name': _concat(user['name'], user['lastname']),
            'appointments': <String>{},
            'payment_count': 0,
            'cents': 0,
          });
      (g['appointments'] as Set<String>).add(_appointmentId(p)!);
      g['payment_count'] = (g['payment_count'] as int) + 1;
      g['cents'] = (g['cents'] as int) + _net(p);
    }
    final rows = [
      for (final g in groups.values)
        {
          'professional_id': g['professional_id'],
          'professional_name': g['professional_name'],
          'appointment_count': (g['appointments'] as Set).length,
          'payment_count': g['payment_count'],
          'total_amount': _money(g['cents'] as int),
          'average_per_payment':
              _money(g['cents'] as int) / (g['payment_count'] as int),
          'percentage_of_total':
              total > 0 ? (g['cents'] as int) * 100 / total : 0,
        },
    ];
    return rows
      ..sort((a, b) => (b['total_amount'] as double)
          .compareTo(a['total_amount'] as double));
  }

  // ------------------------------------------------------- Mejores clientes

  /// `GET /payments/stats/top-clients`.
  List<Map<String, dynamic>> topClients(DateTime from, DateTime to,
      {required int limit}) {
    final groups = <String, Map<String, dynamic>>{};
    for (final p in _paid(window(from, to))) {
      final appointment = data.appointments[_appointmentId(p)];
      final client = JsonRead.asMap(appointment?['client']);
      final clientId = JsonRead.asOptionalString(client?['id']);
      if (clientId == null) continue;
      final local = data.clients[clientId];
      final g = groups.putIfAbsent(clientId, () => {
            'client_id': clientId,
            'client_name': local != null
                ? _concat(local.name, local.lastname)
                : _concat(client?['name'], client?['lastname']),
            'visits': <String>{},
            'cents': 0,
          });
      (g['visits'] as Set<String>).add(_appointmentId(p)!);
      g['cents'] = (g['cents'] as int) + _net(p);
    }
    final rows = [
      for (final g in groups.values)
        {
          'client_id': g['client_id'],
          'client_name': g['client_name'],
          'visit_count': (g['visits'] as Set).length,
          'total_spent': _money(g['cents'] as int),
        },
    ]..sort((a, b) {
        // El SQL no desempata; aquí, por id para que sea estable.
        final byTotal =
            (b['total_spent'] as double).compareTo(a['total_spent'] as double);
        return byTotal != 0
            ? byTotal
            : (a['client_id'] as String).compareTo(b['client_id'] as String);
      });
    return rows.take(limit).toList();
  }

  // ---------------------------------------------------- Por profesional (1)

  /// `GET /payments/employee-stats`.
  Map<String, dynamic> employeeStats(
      DateTime from, DateTime to, String professionalId) {
    final w = window(from, to);
    final paid = _paid(w, professionalId: professionalId);
    final total = paid.fold<int>(0, (s, p) => s + _net(p));
    final days = <String, Map<String, dynamic>>{};
    for (final p in paid) {
      final day = _day(_instant(p['created_at'])!);
      final d = days.putIfAbsent(day, () => {
            'date': day,
            'cents': 0,
            'payments': 0,
            'appointments': <String?>{},
          });
      d['cents'] = (d['cents'] as int) + _net(p);
      d['payments'] = (d['payments'] as int) + 1;
      (d['appointments'] as Set<String?>).add(_appointmentId(p));
    }
    final sortedDays = days.keys.toList()..sort();
    return {
      'summary': {
        'total_amount': _money(total),
        'payment_count': paid.length,
        'appointment_count': {for (final p in paid) _appointmentId(p)}.length,
        'average_per_payment': paid.isEmpty ? 0 : _money(total) / paid.length,
      },
      'by_service': [
        for (final r in _serviceRevenue(w, professionalId: professionalId))
          {
            'service_id': r['service_id'],
            'service_name': r['service_name'],
            'count': r['appointment_count'],
            'total': r['total_amount'],
          },
      ],
      'daily_evolution': [
        for (final day in sortedDays)
          {
            'date': day,
            'total': _money(days[day]!['cents'] as int),
            'count': days[day]!['payments'],
            'payment_count': days[day]!['payments'],
            'appointment_count': (days[day]!['appointments'] as Set).length,
          },
      ],
    };
  }

  // ------------------------------------------------------------ Comisiones

  /// % de la línea: el congelado si el registro lo trae; si no, el que
  /// aplicaría hoy (excepción del servicio o la general del profesional).
  double _linePercent(Map<String, dynamic> line, String professionalId) {
    final frozen = line['commission_percentage'];
    if (frozen != null) return JsonRead.asDouble(frozen);
    final serviceId = JsonRead.asString(line['id']);
    final exception = data.userServices
        .where((u) =>
            u['userId'] == professionalId && u['serviceId'] == serviceId)
        .map((u) => u['commissionPercentage'])
        .firstOrNull;
    if (exception != null) return JsonRead.asDouble(exception);
    return JsonRead.asDouble(data.users[professionalId]?['commission_percentage']);
  }

  /// `commissionCents`: precio × % redondeado al centavo.
  static int commissionCents(int priceCents, double percent) {
    final hundredths = (percent * 100).round();
    return (priceCents * hundredths / 10000).round();
  }

  /// `GET /payments/stats/commissions` (`settleCommissions`).
  Map<String, dynamic> commissions(DateTime from, DateTime to,
      {String? professionalId}) {
    final w = window(from, to);
    final professionals = <String, Map<String, dynamic>>{};
    var grandTotal = 0;
    var grandCommission = 0;
    final appointments = [
      for (final a in data.appointments.values)
        if (a['status'] == 'COMPLETED' &&
            _within(_instant(a['date']), w) &&
            (professionalId == null || a['professionalId'] == professionalId))
          a,
    ]..sort((a, b) => _instant(a['date'])!.compareTo(_instant(b['date'])!));
    for (final a in appointments) {
      final proId = JsonRead.asString(a['professionalId']);
      final user = data.users[proId] ?? JsonRead.asMap(a['professional']) ?? {};
      final pro = professionals.putIfAbsent(proId, () => {
            'professional_id': proId,
            'professional_name': _trimJoin(user['name'], user['lastname']),
            'total': 0,
            'commission': 0,
            'appointments': <Map<String, dynamic>>[],
          });
      final client = JsonRead.asMap(a['client']);
      final local = data.clients[JsonRead.asOptionalString(client?['id'])];
      var total = 0;
      var commission = 0;
      final lines = [
        for (final line in JsonRead.asMapList(a['services']))
          () {
            final price = _cents(line['appointment_price'] ?? line['price']);
            final percent = _linePercent(line, proId);
            final cut = commissionCents(price, percent);
            total += price;
            commission += cut;
            return {
              'service_id': JsonRead.asString(line['id']),
              'service_name': JsonRead.asString(line['name']),
              'price': _money(price),
              'commission_percentage': percent,
              'commission': _money(cut),
            };
          }(),
      ]..sort((x, y) =>
          (x['service_name'] as String).compareTo(y['service_name'] as String));
      (pro['appointments'] as List).add({
        'appointment_id': a['id'],
        'date': a['date'],
        'timezone': a['timezone'],
        'client_name': local != null
            ? _trimJoin(local.name, local.lastname)
            : _trimJoin(client?['name'], client?['lastname']),
        ..._amounts(total, commission),
        'lines': lines,
      });
      pro['total'] = (pro['total'] as int) + total;
      pro['commission'] = (pro['commission'] as int) + commission;
      grandTotal += total;
      grandCommission += commission;
    }
    final list = [
      for (final p in professionals.values)
        {
          'professional_id': p['professional_id'],
          'professional_name': p['professional_name'],
          'appointment_count': (p['appointments'] as List).length,
          ..._amounts(p['total'] as int, p['commission'] as int),
          'appointments': p['appointments'],
        },
    ]..sort((a, b) => (a['professional_name'] as String)
        .compareTo(b['professional_name'] as String));
    return {
      'start': _day(w.start),
      'end': _endDay(to),
      'timezone': BusinessTimeZone.current,
      'totals': {
        ..._amounts(grandTotal, grandCommission),
        'appointment_count': appointments.length,
      },
      'professionals': list,
    };
  }

  /// El día escrito de fin (el modelo lee el prefijo `yyyy-MM-dd`).
  static String _endDay(DateTime to) =>
      DateCodec.encodeDay(DateTime(to.year, to.month, to.day));

  static Map<String, dynamic> _amounts(int total, int commission) => {
        'services_total': _money(total),
        'professional_total': _money(commission),
        'business_total': _money(total - commission),
      };

  /// `TRIM(CONCAT_WS(' ', name, lastname))`.
  static String _trimJoin(Object? name, Object? lastname) => [
        JsonRead.asString(name),
        JsonRead.asString(lastname),
      ].where((p) => p.isNotEmpty).join(' ').trim();
}
