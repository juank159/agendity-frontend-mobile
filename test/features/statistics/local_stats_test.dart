import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/statistics/data/datasources/statistics_remote_datasource.dart';
import 'package:login_signup/features/statistics/data/local/local_stats.dart';
import 'package:login_signup/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';
import '../../core/sync/fake_sync_api.dart';

/// Datos del caso (Bogotá). Las cifras esperadas salen de las fórmulas del
/// backend (`payment-stats.service.ts`, `appointment-commission.ts`) sobre
/// estos mismos datos.
Map<String, dynamic> appointment(String id, String pro, String client,
        String status, String date, List<Map<String, dynamic>> lines) =>
    {
      'id': id,
      'professionalId': pro,
      'client': {'id': client},
      'status': status,
      'date': date,
      'timezone': 'America/Bogota',
      'services': lines,
    };

Map<String, dynamic> line(String id, String name, String price,
        [Object? percent]) =>
    {
      'id': id,
      'name': name,
      'price': '99999.00', // precio actual del catálogo: no se usa
      'appointment_price': price,
      'commission_percentage': percent,
    };

Map<String, dynamic> payment(String id, String appointmentId, String amount,
        String createdAt,
        {String status = 'COMPLETED',
        String? method = 'CASH',
        String? custom,
        String? refund}) =>
    {
      'id': id,
      'appointment': appointmentId,
      'amount': amount,
      'payment_method': method,
      'custom_payment_method_id': custom,
      'status': status,
      'refund_amount': refund,
      'created_at': createdAt,
    };

final data = LocalStatsData(
  appointments: {
    'a1': appointment('a1', 'pro-1', 'cli-1', 'COMPLETED',
        '2026-10-20T10:00:00.000-05:00', [
      line('s1', 'Corte', '30000.00', '30.00'),
      line('s2', 'Barba', '20000.00'), // sin % congelado → el de hoy
    ]),
    'a2': appointment('a2', 'pro-2', 'cli-2', 'COMPLETED',
        '2026-10-21T15:00:00.000-05:00', [
      line('s1', 'Corte', '0.00', '50.00'),
      line('s3', 'Tinte', '0.00', '50.00'),
    ]),
    'a3': appointment('a3', 'pro-1', 'cli-1', 'CANCELLED',
        '2026-10-21T09:00:00.000-05:00', [line('s1', 'Corte', '30000.00')]),
  },
  payments: [
    payment('p1', 'a1', '50000.00', '2026-10-20T10:30:00.000-05:00'),
    // 23:30 del 21 en Bogotá (= 04:30Z del 22): sigue siendo el 21.
    payment('p2', 'a2', '40000.00', '2026-10-21T23:30:00.000-05:00',
        method: null, custom: 'cm-1', refund: '10000.00'),
    payment('p3', 'a1', '5000.00', '2026-10-20T11:00:00.000-05:00',
        status: 'REFUNDED', refund: '5000.00'),
    payment('p4', 'a2', '7000.00', '2026-10-19T12:00:00.000-05:00'),
  ],
  clients: {
    'cli-1': (name: 'Ana', lastname: 'Pérez'),
    'cli-2': (name: 'Carla', lastname: ''),
  },
  users: {
    'pro-1': {
      'id': 'pro-1',
      'name': 'Laura',
      'lastname': 'Gómez',
      'commission_percentage': '10.00',
    },
    'pro-2': {'id': 'pro-2', 'name': 'Beto', 'lastname': ''},
  },
  customMethods: {
    'cm-1': {'id': 'cm-1', 'name': 'Nequi'},
  },
);

final from = DateTime(2026, 10, 20);
final to = DateTime(2026, 10, 21);

void main() {
  setUp(() => BusinessTimeZone.use('America/Bogota'));
  tearDown(BusinessTimeZone.reset);

  final local = LocalStats(data);

  test('totales: pagos COMPLETED netos del periodo (día del negocio)', () {
    expect(local.paymentStats(from, to), {
      'total_amount': 80000.0,
      'payment_count': 2,
      'average_amount': 40000.0,
    });
  });

  test('comparación: periodo anterior de la misma duración; % a 2 '
      'decimales; null si el anterior es 0', () {
    final c = local.comparison(from, to);
    expect(c['current_period']['start_date'], '2026-10-20');
    expect(c['current_period']['end_date'], '2026-10-21');
    expect(c['previous_period']['start_date'], '2026-10-18');
    expect(c['previous_period']['end_date'], '2026-10-19');
    expect(c['previous_period']['total_amount'], 7000.0);
    expect(c['change'], {
      'amount_difference': 73000.0,
      'amount_percentage': 1042.86,
      'count_difference': 1,
      'count_percentage': 100.0,
      'average_difference': 33000.0,
      'average_percentage': 471.43,
    });
    final empty = LocalStats(LocalStatsData(payments: [data.payments.first]))
        .comparison(from, to);
    expect(empty['change']['amount_percentage'], isNull);
  });

  test('por método: estándar y propios por nombre, % del total, de mayor a '
      'menor', () {
    expect(local.byMethod(from, to), [
      {
        'method': 'CASH',
        'method_type': 'STANDARD',
        'custom_payment_method_id': null,
        'count': 1,
        'total': 50000.0,
        'average': 50000.0,
        'percentage': 62.5,
      },
      {
        'method': 'Nequi',
        'method_type': 'CUSTOM',
        'custom_payment_method_id': 'cm-1',
        'count': 1,
        'total': 30000.0,
        'average': 30000.0,
        'percentage': 37.5,
      },
    ]);
  });

  test('por servicio: lo pagado se reparte por el precio guardado en la cita '
      '(a partes iguales si todo vale 0)', () {
    final rows = local.byService(from, to);
    expect(rows.map((r) => (r['service_name'], r['total_amount'],
        r['appointment_count'], r['payment_count'])), [
      ('Corte', 45000.0, 2, 2),
      ('Barba', 20000.0, 1, 1),
      ('Tinte', 15000.0, 1, 1),
    ]);
    expect(rows.first['average_amount'], 22500.0);
    expect(rows.map((r) => r['percentage_of_total']), [56.25, 25.0, 18.75]);
  });

  test('por profesional: CONCAT con espacio (como el SQL), % del total', () {
    expect(local.byProfessional(from, to).map((r) => (r['professional_name'],
        r['total_amount'], r['appointment_count'], r['percentage_of_total'])), [
      ('Laura Gómez', 50000.0, 1, 62.5),
      ('Beto ', 30000.0, 1, 37.5),
    ]);
    expect(const LocalStats(LocalStatsData()).byProfessional(from, to),
        isEmpty);
  });

  test('mejores clientes: nombre de la ficha local, visitas y gasto', () {
    expect(local.topClients(from, to, limit: 1), [
      {
        'client_id': 'cli-1',
        'client_name': 'Ana Pérez',
        'visit_count': 1,
        'total_spent': 50000.0,
      },
    ]);
  });

  test('un profesional: resumen, por servicio y evolución diaria', () {
    final e = local.employeeStats(from, to, 'pro-1');
    expect(e['summary'], {
      'total_amount': 50000.0,
      'payment_count': 1,
      'appointment_count': 1,
      'average_per_payment': 50000.0,
    });
    expect((e['by_service'] as List).map((r) => (r['service_name'], r['total'])),
        [('Corte', 30000.0), ('Barba', 20000.0)]);
    expect(e['daily_evolution'], [
      {
        'date': '2026-10-20',
        'total': 50000.0,
        'count': 1,
        'payment_count': 1,
        'appointment_count': 1,
      },
    ]);
  });

  test('comisiones: citas COMPLETED por fecha, % congelado (o el de hoy), '
      'redondeo al centavo y profesionales por nombre', () {
    final c = local.commissions(from, to);
    expect(c['totals'], {
      'services_total': 50000.0,
      'professional_total': 11000.0,
      'business_total': 39000.0,
      'appointment_count': 2,
    });
    final pros = c['professionals'] as List;
    expect(pros.map((p) => p['professional_name']), ['Beto', 'Laura Gómez']);
    final laura = pros.last['appointments'].single;
    expect(laura['client_name'], 'Ana Pérez');
    expect(
        (laura['lines'] as List)
            .map((l) => (l['service_name'], l['commission_percentage'], l['commission'])),
        [('Barba', 10.0, 2000.0), ('Corte', 30.0, 9000.0)]);
    expect(c['start'], '2026-10-20');
    expect(c['end'], '2026-10-21');
    expect(LocalStats.commissionCents(3333, 33.33), 1111,
        reason: '3333 × 33,33 % = 1110,89 → 1111');
    expect(local.commissions(from, to, professionalId: 'pro-2')['totals']
        ['appointment_count'], 1);
  });

  group('repositorio: con conexión manda el servidor; sin ella, local', () {
    late LocalDatabaseHolder databases;
    late FakeHttpClientAdapter adapter;
    late StatisticsRepositoryImpl repository;
    String userId = 'owner-1';

    /// Lo que bajó a la base del usuario de la sesión (una por usuario).
    Future<void> seed() async {
      final db = await databases.require();
      for (final (id, owner) in [('owner-1', true), ('pro-1', false)]) {
        await DocumentStore.put(db, SharedDocs.users, id, {
          'id': id,
          'name': id,
          'roles': [
            {'name': owner ? 'Owner' : 'Employee'}
          ],
        });
      }
      for (final a in data.appointments.values) {
        await DocumentStore.put(db, SharedDocs.appointments, a['id'], a);
      }
      for (final p in data.payments) {
        await DocumentStore.put(
            db, const DocumentKind('payments'), p['id'], p);
      }
    }

    setUp(() async {
      databases = memoryDatabases(userId: () => userId);
      adapter = FakeHttpClientAdapter((_) => jsonBody(200, {
            'total_amount': 1,
            'payment_count': 1,
            'average_amount': 1,
          }));
      repository = StatisticsRepositoryImpl(
        StatisticsRemoteDataSourceImpl(buildApiClient(
            baseUrl: 'http://api.test/api',
            tokenStore: MemoryTokenStore('jwt'),
            httpClientAdapter: adapter,
            retryDelay: (_) => Duration.zero,
            enableLogs: false)),
        store: OfflineStore(databases: databases),
      );
      await seed();
    });

    tearDown(() => databases.close());

    final range = StatsRange(start: from, end: to);

    test('con conexión: las cifras del servidor', () async {
      final result = await repository.getPaymentStats(range);
      expect(result.getOrElse(() => throw StateError('L')).totalAmount, 1);
    });

    test('sin conexión (Owner): calculadas en local', () async {
      adapter.handler = connectionError;
      final result = await repository.getPaymentStats(range);
      expect(result.getOrElse(() => throw StateError('L')).totalAmount, 80000);
    });

    test('sin conexión, Employee: no tiene los pagos → NetworkFailure; sus '
        'comisiones sí, solo las suyas', () async {
      adapter.handler = connectionError;
      userId = 'pro-1';
      await seed(); // su propia base
      expect(
          (await repository.getPaymentStats(range)).fold((f) => f, (_) => null),
          isA<NetworkFailure>());
      final mine = (await repository.getCommissionSettlement(range))
          .getOrElse(() => throw StateError('L'));
      expect(mine.professionals.map((p) => p.professionalId), ['pro-1']);
      expect(
          (await repository.getCommissionSettlement(range,
                  professionalId: 'pro-2'))
              .fold((f) => f, (_) => null),
          isA<NetworkFailure>());
      userId = 'owner-1';
    });

    test('un error que no es de red no se tapa con el cálculo local', () async {
      adapter.handler = (_) => jsonBody(403, {
            'statusCode': 403,
            'code': 'FORBIDDEN',
            'message': 'No',
          });
      expect(
          (await repository.getPaymentStats(range)).fold((f) => f, (_) => null),
          isA<ForbiddenFailure>());
    });
  });
}
