import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:login_signup/features/appointments/data/sync/appointments_sync.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_changes.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';
import 'package:login_signup/features/appointments/domain/usecases/create_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/update_appointment_usecase.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';
import '../../core/sync/fake_sync_api.dart';
import 'appointment_model_test.dart' show backendAppointment, backendService;

Failure? leftOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => null);

T rightOf<T>(Either<Failure, T> result) =>
    result.getOrElse(() => throw StateError('Left: ${leftOf(result)}'));

Map<String, dynamic> bodyOf(RequestOptions request) =>
    request.data is String
        ? jsonDecode(request.data as String) as Map<String, dynamic>
        : Map<String, dynamic>.from(request.data as Map);

ResponseBody conflictBody(String code, Map<String, dynamic> details) =>
    jsonBody(409, {
      'statusCode': 409,
      'code': code,
      'message': code == 'SLOT_UNAVAILABLE'
          ? 'Horario no disponible'
          : 'El negocio está cerrado a esa hora',
      'details': details,
    });

/// "Ahora" fijo (hora de pared del negocio, Bogotá).
final now = DateTime(2026, 11, 1, 8);

/// 13.05 (D-25): con conexión, agendar y mover van directo al servidor
/// (estricto); sin conexión o si la petición no llega, por la bandeja (D-18).
void main() {
  late FakeHttpClientAdapter adapter;
  late LocalDatabaseHolder databases;
  late AppDatabase db;
  late AppointmentsRepositoryImpl repository;
  late bool online;
  late int flushes;
  Future<void> Function()? onFlush;
  var ids = 0;

  setUp(() async {
    BusinessTimeZone.use('America/Bogota');
    BusinessTimeZone.clock = () => DateTime.utc(2026, 11, 1, 13); // 08:00
    adapter = FakeHttpClientAdapter((_) => jsonBody(200, {}));
    final dio = buildApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: MemoryTokenStore('jwt'),
      httpClientAdapter: adapter,
      retryDelay: (_) => Duration.zero,
      enableLogs: false,
    );
    databases = memoryDatabases();
    ids = 0;
    online = true;
    flushes = 0;
    onFlush = null;
    repository = AppointmentsRepositoryImpl(
      AppointmentsRemoteDataSourceImpl(dio),
      store: OfflineStore(
        databases: databases,
        newId: () => 'apt-new-${++ids}',
        clock: () => DateTime.utc(2026, 11, 1, 13),
      ),
      isOnline: () => online,
      flush: () async {
        flushes++;
        await onFlush?.call();
      },
    );
    db = await databases.require();

    await db.into(db.localClients).insert(LocalClientsCompanion.insert(
        id: 'cli-1', name: 'Ana', phone: '3001234567'));
    await DocumentStore.put(db, SharedDocs.users, 'pro-1', {
      'id': 'pro-1',
      'name': 'Laura',
      'lastname': 'Gómez',
      'isActive': true,
      'roles': [
        {'name': 'Employee'}
      ],
    });
    for (final service in [
      backendService(), // svc-1, 45 min
      backendService(id: 'svc-2', name: 'Barba', duration: 30, price: '20000.00'),
    ]) {
      await DocumentStore.put(db, const DocumentKind('services'),
          service['id'] as String,
          {...service, 'isActive': true}..remove('appointment_price'));
    }
  });

  tearDown(() async {
    BusinessTimeZone.reset();
    BusinessTimeZone.clock = DateTime.now;
    await databases.close();
  });

  Future<List<OutboxEntry>> outbox() => OutboxStore.all(db);

  Future<List<Map<String, dynamic>>> localAppointments() =>
      DocumentStore.list(db, AppointmentsSync.kind.entity);

  final newAppointment = NewAppointment(
    clientId: 'cli-1',
    professionalId: 'pro-1',
    serviceIds: const ['svc-1'],
    start: DateTime(2026, 11, 3, 10),
  );

  Future<Either<Failure, AppointmentEntity>> create() =>
      CreateAppointmentUseCase(repository, now: () => now)(newAppointment);

  /// Lo que responde `POST /appointments`: la cita con la forma de la API.
  ResponseBody created(RequestOptions request) => jsonBody(201, {
        ...backendAppointment(
            id: bodyOf(request)['id'] as String,
            date: '2026-11-03T10:00:00.000-05:00'),
        'notes': '',
      });

  group('agendar con conexión', () {
    test('201 → POST con el id de la app; la cita queda en local, sin bandeja',
        () async {
      adapter.handler = created;
      final appointment = rightOf(await create());

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/appointments');
      expect(bodyOf(request), {
        'id': 'apt-new-1',
        'client_id': 'cli-1',
        'professional_id': 'pro-1',
        'service_ids': ['svc-1'],
        'date': '2026-11-03T15:00:00.000Z',
      });
      expect(appointment.id, 'apt-new-1');
      expect(appointment.client.name, 'Ana');
      expect(appointment.startTime, DateTime(2026, 11, 3, 10));
      expect(await outbox(), isEmpty);
      expect(flushes, 0, reason: 'la bandeja estaba vacía');

      // La agenda la ve ya (lectura local).
      final day = rightOf(await repository.getAppointments(AppointmentsRange(
          start: DateTime(2026, 11, 3), end: DateTime(2026, 11, 4))));
      expect(day.map((a) => a.id), ['apt-new-1']);

      // La bajada trae la misma cita (mismo id): no se duplica.
      final doc = (await DocumentStore.get(db, 'appointments', 'apt-new-1'))!;
      await AppointmentsSync.handlers()
          .first
          .upsert(db, 'apt-new-1', {...doc, 'notes': 'desde la bajada'});
      final docs = await localAppointments();
      expect(docs, hasLength(1));
      expect(docs.single['notes'], 'desde la bajada');
    });

    test(
        '409 SLOT_UNAVAILABLE → failure con motivo y franjas; nada en local '
        'ni en la bandeja', () async {
      adapter.handler = (_) => conflictBody('SLOT_UNAVAILABLE', {
            'reason': 'PROFESSIONAL_OFF_SCHEDULE',
            'hours': [
              {'start': '09:00', 'end': '13:00'},
              {'start': '14:00', 'end': '18:00'},
            ],
          });
      final failure = leftOf(await create());

      expect(failure, isA<SlotUnavailableFailure>());
      failure as SlotUnavailableFailure;
      expect(failure.reason, SlotUnavailableReason.professionalOffSchedule);
      expect(failure.hours, const [
        WorkHours(start: '09:00', end: '13:00'),
        WorkHours(start: '14:00', end: '18:00'),
      ]);
      expect(failure.message, 'Horario no disponible');
      expect(await localAppointments(), isEmpty);
      expect(await outbox(), isEmpty);
    });

    test('409 OUTSIDE_BUSINESS_HOURS → failure con motivo; nada en local',
        () async {
      adapter.handler = (_) => conflictBody('OUTSIDE_BUSINESS_HOURS', {
            'reason': 'OUTSIDE_OPENING_HOURS',
            'hours': [
              {'start': '08:00', 'end': '12:00'},
            ],
          });
      final failure = leftOf(await create());
      expect(failure, isA<OutsideBusinessHoursFailure>());
      failure as OutsideBusinessHoursFailure;
      expect(failure.reason, OutsideBusinessHoursReason.outsideOpeningHours);
      expect(failure.hours, const [WorkHours(start: '08:00', end: '12:00')]);
      expect(await localAppointments(), isEmpty);
      expect(await outbox(), isEmpty);
    });

    test('otro error del servidor (500, cupo agotado) también es estricto',
        () async {
      adapter.handler = (_) => jsonBody(402, {
            'statusCode': 402,
            'code': 'TRIAL_LIMIT_REACHED',
            'message': 'Se acabó la prueba',
          });
      expect(leftOf(await create()), isA<TrialLimitReachedFailure>());
      adapter.handler = (_) => jsonBody(500,
          {'statusCode': 500, 'code': 'INTERNAL_ERROR', 'message': 'x'});
      expect(leftOf(await create()), isA<ServerFailure>());
      expect(await localAppointments(), isEmpty);
      expect(await outbox(), isEmpty);
    });

    test('error de red → por la bandeja, como sin conexión (no se pierde)',
        () async {
      adapter.handler = connectionError;
      final appointment = rightOf(await create());
      expect(adapter.requests, hasLength(1));
      final entry = (await outbox()).single;
      expect(entry.type, 'appointment.create');
      expect(entry.entityId, appointment.id);
      expect(entry.payload.containsKey('id'), isFalse);
      expect(await localAppointments(), hasLength(1));
    });

    test('timeout o 503 → por la bandeja', () async {
      adapter.handler = (options) => throw DioException.receiveTimeout(
          timeout: const Duration(seconds: 30), requestOptions: options);
      rightOf(await create());
      adapter.handler = (_) => textBody(503, '<html>Service Unavailable</html>');
      rightOf(await create());
      expect((await outbox()).map((e) => e.type),
          ['appointment.create', 'appointment.create']);
    });

    test('sin conexión conocida → bandeja sin intentar la red', () async {
      online = false;
      rightOf(await create());
      expect(adapter.requests, isEmpty);
      expect((await outbox()).single.type, 'appointment.create');
    });

    test(
        'cliente recién creado aún en la bandeja: primero se sube; si sale, '
        'va directo', () async {
      await OutboxStore.enqueue(db,
          mutationId: 'm-cli',
          type: 'client.create',
          entity: 'clients',
          entityId: 'cli-1',
          clientTime: DateTime.utc(2026, 11, 1, 13));
      // La sincronización lo sube (el servidor lo aplicó).
      onFlush = () => OutboxStore.remove(db, 'm-cli');
      adapter.handler = created;

      rightOf(await create());
      expect(flushes, 1);
      expect(adapter.requests.single.method, 'POST');
      expect(await outbox(), isEmpty);
    });

    test('si el cliente sigue en la bandeja tras subir → por la bandeja',
        () async {
      await OutboxStore.enqueue(db,
          mutationId: 'm-cli',
          type: 'client.create',
          entity: 'clients',
          entityId: 'cli-1',
          clientTime: DateTime.utc(2026, 11, 1, 13));
      rightOf(await create());
      expect(flushes, 1);
      expect(adapter.requests, isEmpty);
      expect((await outbox()).map((e) => e.type),
          ['client.create', 'appointment.create']);
    });

    test('cliente fusionado por el servidor: se agenda con el id nuevo',
        () async {
      await db.into(db.idRemaps).insert(IdRemapsCompanion.insert(
          entity: 'clients', fromId: 'cli-local', toId: 'cli-1'));
      adapter.handler = created;
      rightOf(await CreateAppointmentUseCase(repository, now: () => now)(
          NewAppointment(
              clientId: 'cli-local',
              professionalId: 'pro-1',
              serviceIds: const ['svc-1'],
              start: DateTime(2026, 11, 3, 10))));
      expect(bodyOf(adapter.requests.single)['client_id'], 'cli-1');
    });
  });

  group('mover con conexión', () {
    setUp(() => DocumentStore.put(
        db,
        AppointmentsSync.kind,
        'apt-1',
        backendAppointment(
          date: '2026-11-03T15:00:00Z',
          services: [backendService()],
        )));

    Future<Either<Failure, AppointmentEntity>> move(
        {DateTime? start, List<String>? serviceIds, String? notes}) async {
      final original = rightOf(await repository.getAppointment('apt-1'));
      return UpdateAppointmentUseCase(repository, now: () => now)(
          UpdateAppointmentParams(
              original: original,
              changes: AppointmentChanges.between(original,
                  start: start, serviceIds: serviceIds, notes: notes)));
    }

    test('200 → PATCH solo con lo que cambia; local = respuesta del servidor',
        () async {
      adapter.handler = (_) => jsonBody(200, {
            ...backendAppointment(date: '2026-11-03T12:00:00.000-05:00'),
            'needsReschedule': false,
          });
      final moved = rightOf(await move(start: DateTime(2026, 11, 3, 12)));

      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.uri.path, '/api/appointments/apt-1');
      expect(bodyOf(request), {'date': '2026-11-03T17:00:00.000Z'});
      expect(moved.startTime, DateTime(2026, 11, 3, 12));
      expect(await outbox(), isEmpty);
    });

    test('409 → failure al formulario y la cita local no cambia', () async {
      adapter.handler = (_) =>
          conflictBody('SLOT_UNAVAILABLE', {'reason': 'APPOINTMENT_OVERLAP'});
      final failure = leftOf(await move(start: DateTime(2026, 11, 3, 12)));

      expect(failure, isA<SlotUnavailableFailure>());
      expect((failure as SlotUnavailableFailure).reason,
          SlotUnavailableReason.appointmentOverlap);
      expect(failure.hours, isEmpty);
      final local = rightOf(await repository.getAppointment('apt-1'));
      expect(local.startTime, DateTime(2026, 11, 3, 10));
      expect(await outbox(), isEmpty);
    });

    test('error de red → por la bandeja (appointment.update)', () async {
      adapter.handler = connectionError;
      final moved = rightOf(await move(serviceIds: const ['svc-1', 'svc-2']));
      expect(moved.serviceNames, ['Corte', 'Barba']);
      final entry = (await outbox()).single;
      expect(entry.type, 'appointment.update');
      expect(entry.payload, {
        'service_ids': ['svc-1', 'svc-2']
      });
    });

    test('cambiar solo las notas no toca la agenda: sigue por la bandeja',
        () async {
      rightOf(await move(notes: 'Con prisa'));
      expect(adapter.requests, isEmpty);
      expect((await outbox()).single.payload, {'notes': 'Con prisa'});
    });

    test(
        'la cita aún tiene cambios en la bandeja (p. ej. creada sin '
        'conexión): moverla sigue por la bandeja, en orden', () async {
      online = false;
      final offline = rightOf(await create());
      online = true;
      final result = await UpdateAppointmentUseCase(repository, now: () => now)(
          UpdateAppointmentParams(
              original: offline,
              changes: AppointmentChanges.between(offline,
                  start: DateTime(2026, 11, 3, 12))));
      rightOf(result);
      // Se intentó subir antes (había pendientes) pero sigue en la bandeja.
      expect(flushes, 1);
      expect(adapter.requests, isEmpty);
      expect((await outbox()).map((e) => e.type),
          ['appointment.create', 'appointment.update']);
    });

    test(
        'creada directo y luego movida sin conexión: la mutación va a la '
        'bandeja sobre la versión del servidor', () async {
      adapter.handler = created;
      final appointment = rightOf(await create());
      online = false;
      final moved = rightOf(await UpdateAppointmentUseCase(repository,
              now: () => now)(UpdateAppointmentParams(
          original: appointment,
          changes: AppointmentChanges.between(appointment,
              start: DateTime(2026, 11, 3, 12)))));
      expect(moved.startTime, DateTime(2026, 11, 3, 12));
      expect(adapter.requests, hasLength(1), reason: 'solo el POST');
      final entry = (await outbox()).single;
      expect(entry.type, 'appointment.update');
      expect(entry.entityId, appointment.id);

      // Si el servidor la rechazara, vuelve a la versión que él guardó.
      await AppointmentsSync.handlers().first.restore(db, appointment.id);
      final restored = rightOf(await repository.getAppointment(appointment.id));
      expect(restored.startTime, DateTime(2026, 11, 3, 10));
    });
  });
}
