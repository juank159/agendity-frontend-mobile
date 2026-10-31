import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/core/sync/sync_models.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:login_signup/features/appointments/data/sync/appointments_sync.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_changes.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';
import 'package:login_signup/features/appointments/domain/usecases/appointment_rules.dart';
import 'package:login_signup/features/appointments/domain/usecases/cancel_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/complete_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/create_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_available_slots_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_upcoming_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/mark_reminder_sent_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/prepare_reminder_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/update_appointment_usecase.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';
import '../../core/sync/fake_sync_api.dart';
import 'appointment_model_test.dart' show backendAppointment, backendService;

Failure? leftOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => null);

T rightOf<T>(Either<Failure, T> result) =>
    result.getOrElse(() => throw StateError('Left: ${leftOf(result)}'));

ResponseBody errorBody(int status, String code, String message) =>
    jsonBody(status, {'statusCode': status, 'code': code, 'message': message});

AppointmentEntity entityOf(Map<String, dynamic> json) =>
    AppointmentModel.fromJson(json).toEntity();

Map<String, dynamic> bodyOf(RequestOptions request) =>
    request.data is String
        ? jsonDecode(request.data as String) as Map<String, dynamic>
        : request.data as Map<String, dynamic>;

/// "Ahora" fijo de los tests (hora de pared del negocio, Bogotá).
final now = DateTime(2026, 11, 1, 8);

/// Citas sin conexión (10.02b): lectura local, escrituras a local + bandeja
/// (`appointment.*`); horas libres y recordatorios con la red.
void main() {
  late FakeHttpClientAdapter adapter;
  late LocalDatabaseHolder databases;
  late AppDatabase db;
  late AppointmentsRepositoryImpl repository;
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
    repository = AppointmentsRepositoryImpl(
      AppointmentsRemoteDataSourceImpl(dio),
      store: OfflineStore(
        databases: databases,
        newId: () => 'apt-new-${++ids}',
        clock: () => DateTime.utc(2026, 11, 1, 13),
      ),
    );
    db = await databases.require();

    // Lo que bajó la sincronización: cliente, profesional y servicios.
    await db.into(db.localClients).insert(LocalClientsCompanion.insert(
        id: 'cli-1', name: 'Ana', phone: '3001234567'));
    await db.into(db.localClients).insert(LocalClientsCompanion.insert(
        id: 'cli-2', name: 'Beto', phone: '3007654321'));
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
      backendService(), // svc-1, 45 min, 50.000
      backendService(id: 'svc-2', name: 'Barba', duration: 30, price: '20000.00'),
    ]) {
      await DocumentStore.put(db, const DocumentKind('services'),
          service['id'] as String,
          {...service, 'isActive': true}..remove('appointment_price'));
    }
    for (final service in ['svc-1', 'svc-2']) {
      await DocumentStore.put(db, SharedDocs.userServices, 'us-$service', {
        'id': 'us-$service',
        'userId': 'pro-1',
        'serviceId': service,
        'isActive': true,
      });
    }
  });

  tearDown(() async {
    BusinessTimeZone.reset();
    BusinessTimeZone.clock = DateTime.now;
    await databases.close();
  });

  Future<void> seed(Map<String, dynamic> json) =>
      DocumentStore.put(db, AppointmentsSync.kind, json['id'] as String, json);

  Future<List<OutboxEntry>> outbox() => OutboxStore.all(db);

  group('leer (local)', () {
    test('rango por instante, ordenado; sin red', () async {
      await seed(backendAppointment(id: 'tarde', date: '2026-11-03T15:00:00Z'));
      await seed(backendAppointment(id: 'fuera', date: '2026-11-05T15:00:00Z'));
      await seed(
          backendAppointment(id: 'temprano', date: '2026-11-03T13:00:00Z'));
      final list = rightOf(await GetAppointmentsUseCase(repository)(
          AppointmentsRange.day(DateTime(2026, 11, 3))));
      expect(list.map((a) => a.id), ['temprano', 'tarde']);
      expect(adapter.requests, isEmpty);
    });

    test('rango invertido → failure; por id; inexistente → NotFound',
        () async {
      expect(
          leftOf(await GetAppointmentsUseCase(repository)(AppointmentsRange(
              start: now, end: now.subtract(const Duration(days: 1))))),
          isA<InvalidAppointmentDataFailure>());
      await seed(backendAppointment());
      expect(rightOf(await GetAppointmentUseCase(repository)('apt-1')).id,
          'apt-1');
      expect(leftOf(await repository.getAppointment('otra')),
          isA<NotFoundFailure>());
    });
  });

  group('crear', () {
    final newAppointment = NewAppointment(
      clientId: ' cli-1 ',
      professionalId: 'pro-1',
      serviceIds: const ['svc-1', 'svc-2'],
      start: DateTime(2026, 11, 3, 10),
      notes: '  ',
    );

    CreateAppointmentUseCase create() =>
        CreateAppointmentUseCase(repository, now: () => now);

    test('se guarda en local con cliente, profesional, servicios y total; '
        'appointment.create con el DTO', () async {
      final created = rightOf(await create()(newAppointment));
      expect(created.id, 'apt-new-1');
      expect(created.client.name, 'Ana');
      expect(created.professionalName, 'Laura Gómez');
      expect(created.serviceNames, ['Corte', 'Barba']);
      expect(created.totalPrice, 70000, reason: 'precios actuales');
      expect(created.duration, const Duration(minutes: 75));
      expect(created.status, AppointmentStatus.PENDING);
      expect(created.startTime, DateTime(2026, 11, 3, 10));
      expect(created.timeZone, 'America/Bogota');

      final entry = (await outbox()).single;
      expect(entry.type, 'appointment.create');
      expect(entry.entityId, 'apt-new-1');
      expect(entry.payload, {
        'client_id': 'cli-1',
        'professional_id': 'pro-1',
        'service_ids': ['svc-1', 'svc-2'],
        'date': '2026-11-03T15:00:00.000Z',
      });
      expect(adapter.requests, isEmpty);
    });

    test('reglas locales: sin servicios, repetidos, en el pasado → sin escribir',
        () async {
      expect(
          leftOf(await create()(NewAppointment(
              clientId: 'cli-1',
              professionalId: 'pro-1',
              serviceIds: const [],
              start: DateTime(2026, 11, 3, 10)))),
          isA<InvalidAppointmentDataFailure>());
      expect(
          leftOf(await create()(NewAppointment(
              clientId: 'cli-1',
              professionalId: 'pro-1',
              serviceIds: const ['svc-1'],
              start: DateTime(2026, 10, 31, 10)))),
          isA<AppointmentInPastFailure>());
      expect(await outbox(), isEmpty);
    });

    test('vuelve como conflict + saved: sale de la bandeja y la bajada la '
        'marca para mover (no ocupa hueco)', () async {
      final server = FakeSyncServer();
      server.forced['appointment.create'] = (mid) => MutationResult(
          mutationId: mid,
          status: MutationStatus.conflict,
          code: 'SLOT_UNAVAILABLE',
          saved: true);
      final engine = SyncEngine(
          databases: databases,
          api: server,
          handlers: AppointmentsSync.handlers());
      final created = rightOf(await create()(newAppointment));
      await engine.syncNow();
      expect(await outbox(), isEmpty);

      // La bajada trae la cita guardada con su conflicto.
      final doc = (await DocumentStore.get(db, 'appointments', created.id))!;
      await AppointmentsSync.handlers().first.upsert(db, created.id, {
        ...doc,
        'needsReschedule': true,
        'syncConflict': 'SLOT_UNAVAILABLE',
      });
      final marked = rightOf(await repository.getAppointment(created.id));
      expect(marked.needsReschedule, true);
      expect(marked.syncConflict, 'SLOT_UNAVAILABLE');
      expect(marked.blocksSlot, false);

      // Moverla limpia el conflicto en local (el servidor decide al subir).
      final moved = rightOf(await UpdateAppointmentUseCase(repository,
              now: () => now)(UpdateAppointmentParams(
          original: marked,
          changes: AppointmentChanges.between(marked,
              start: DateTime(2026, 11, 3, 12)))));
      expect(moved.needsReschedule, false);
      expect(moved.syncConflict, isNull);
      await engine.dispose();
    });
  });

  group('editar', () {
    setUp(() => seed(backendAppointment(
          date: '2026-11-03T15:00:00Z',
          services: [
            backendService(),
            backendService(id: 'svc-2', name: 'Barba'),
          ],
          reminderSent: true,
        )));

    UpdateAppointmentUseCase update() =>
        UpdateAppointmentUseCase(repository, now: () => now);

    test('solo lo que cambia; sin cambios no escribe', () async {
      final original = rightOf(await repository.getAppointment('apt-1'));
      final changes = AppointmentChanges.between(
        original,
        clientId: 'cli-1',
        professionalId: 'pro-1',
        serviceIds: const ['svc-2', 'svc-1'],
        start: original.startTime,
        notes: ' Con prisa ',
      );
      rightOf(await update()(
          UpdateAppointmentParams(original: original, changes: changes)));
      expect((await outbox()).single.payload, {'notes': 'Con prisa'});

      final same = rightOf(await update()(UpdateAppointmentParams(
          original: original,
          changes: AppointmentChanges.between(original, notes: 'Sin prisa'))));
      expect(same.id, 'apt-1');
      expect((await outbox()).length, 1);
    });

    test('cambiar servicios conserva el precio de los que ya tenía; mover '
        'reinicia el recordatorio manual', () async {
      final original = rightOf(await repository.getAppointment('apt-1'));
      final edited = rightOf(await update()(UpdateAppointmentParams(
          original: original,
          changes: AppointmentChanges.between(original,
              clientId: 'cli-2',
              serviceIds: const ['svc-1'],
              start: DateTime(2026, 11, 4, 10)))));
      expect(edited.client.name, 'Beto');
      expect(edited.services.single.price, 45000,
          reason: 'conserva el precio guardado en la cita, no el actual');
      expect(edited.totalPrice, 45000);
      expect(edited.startTime, DateTime(2026, 11, 4, 10));
      expect(edited.reminderSent, false);
    });

    test('mover al pasado → AppointmentInPastFailure sin escribir', () async {
      final original = rightOf(await repository.getAppointment('apt-1'));
      expect(
          leftOf(await update()(UpdateAppointmentParams(
              original: original,
              changes: AppointmentChanges.between(original,
                  start: DateTime(2026, 10, 30, 10))))),
          isA<AppointmentInPastFailure>());
      expect(await outbox(), isEmpty);
    });
  });

  group('cancelar y completar', () {
    test('cancelar con motivo; con algo pagado → AppointmentPaidFailure',
        () async {
      await seed(backendAppointment());
      final cancelled = rightOf(await CancelAppointmentUseCase(repository)(
          const CancelAppointmentParams(appointmentId: 'apt-1', reason: ' Viaje ')));
      expect(cancelled.status, AppointmentStatus.CANCELLED);
      expect(cancelled.cancellationReason, 'Viaje');
      final entry = (await outbox()).single;
      expect(entry.type, 'appointment.cancel');
      expect(entry.payload, {'cancellation_reason': 'Viaje'});

      await seed(backendAppointment(id: 'pagada', paymentStatus: 'PARTIAL'));
      expect(leftOf(await repository.cancelAppointment('pagada')),
          isA<AppointmentPaidFailure>());
    });

    test('motivo de más de 500 caracteres → failure sin escribir', () async {
      await seed(backendAppointment());
      expect(
          leftOf(await CancelAppointmentUseCase(repository)(
              CancelAppointmentParams(
                  appointmentId: 'apt-1',
                  reason: 'x' *
                      (AppointmentRules.maxCancellationReasonLength + 1)))),
          isA<InvalidAppointmentDataFailure>());
      expect(await outbox(), isEmpty);
    });

    test('completar: antes de empezar → AppointmentNotStarted; ya empezada → '
        'COMPLETED; una cancelada → InvalidStateTransition', () async {
      await seed(backendAppointment(date: '2026-11-03T15:00:00Z'));
      expect(leftOf(await CompleteAppointmentUseCase(repository)('apt-1')),
          isA<AppointmentNotStartedFailure>());
      await seed(backendAppointment(id: 'ayer', date: '2026-10-31T15:00:00Z'));
      expect(rightOf(await repository.completeAppointment('ayer')).status,
          AppointmentStatus.COMPLETED);
      expect((await outbox()).single.type, 'appointment.complete');
      await seed(backendAppointment(
          id: 'cancelada', date: '2026-10-31T15:00:00Z', status: 'CANCELLED'));
      expect(leftOf(await repository.completeAppointment('cancelada')),
          isA<InvalidStateTransitionFailure>());
    });
  });

  group('horas libres', () {
    final query = AvailableSlotsQuery(
      professionalId: 'pro-1',
      day: DateTime(2026, 11, 3),
      serviceIds: const ['svc-1'],
      stepMinutes: 30,
    );

    test('con conexión: las del servidor', () async {
      adapter.handler = (_) => jsonBody(200, [
            '2026-11-03T09:00:00.000-05:00',
            '2026-11-03T09:30:00.000-05:00',
          ]);
      expect(rightOf(await GetAvailableSlotsUseCase(repository)(query)),
          [DateTime(2026, 11, 3, 9), DateTime(2026, 11, 3, 9, 30)]);
      expect(adapter.requests.single.uri.path,
          '/api/appointments/available-slots');
    });

    test('sin conexión: calculadas en local (horario del negocio ∩ '
        'profesional, citas, bloqueos y duración)', () async {
      adapter.handler = connectionError;
      await DocumentStore.put(db, SharedDocs.businessSettings, 'owner-1', {
        'tenant_id': 'owner-1',
        'timezone': 'America/Bogota',
        'opening_hours': [
          {'day_of_week': 2, 'start_time': '09:00', 'end_time': '13:00'},
        ],
      });
      await DocumentStore.put(db, SharedDocs.schedules, 'sch-1', {
        'id': 'sch-1',
        'user': 'pro-1',
        'day_of_week': 2, // martes 3 de noviembre
        'start_time': '10:00:00',
        'end_time': '18:00:00',
        'is_available': true,
      });
      // Cita de 10:30 a 11:15 y un bloqueo de 12:15 a 12:30.
      await seed(backendAppointment(date: '2026-11-03T10:30:00.000-05:00'));
      await seed(backendAppointment(
          id: 'cancelada',
          date: '2026-11-03T11:30:00.000-05:00',
          status: 'CANCELLED'));
      await DocumentStore.put(db, AppointmentsSync.timeBlocks, 'tb-1', {
        'id': 'tb-1',
        'user': 'pro-1',
        'start_datetime': '2026-11-03T12:15:00.000-05:00',
        'end_datetime': '2026-11-03T12:30:00.000-05:00',
      });

      final slots = rightOf(await GetAvailableSlotsUseCase(repository)(query));
      // Ventana 10:00–13:00 (negocio ∩ profesional), 45 min cada 30.
      expect(slots, [
        DateTime(2026, 11, 3, 11, 30), // la cancelada no ocupa
      ]);
    });

    test('sin conexión: servicio que no hace o desactivado', () async {
      adapter.handler = connectionError;
      await DocumentStore.put(db, SharedDocs.userServices, 'us-svc-2', {
        'id': 'us-svc-2',
        'userId': 'pro-1',
        'serviceId': 'svc-2',
        'isActive': false,
      });
      expect(
          leftOf(await repository.getAvailableSlots(AvailableSlotsQuery(
              professionalId: 'pro-1',
              day: DateTime(2026, 11, 3),
              serviceIds: const ['svc-2']))),
          isA<ServiceNotOfferedFailure>());
      await DocumentStore.merge(db, const DocumentKind('services'), 'svc-1',
          {'isActive': false});
      expect(leftOf(await repository.getAvailableSlots(query)),
          isA<ServiceInactiveFailure>());
    });

    test('con conexión, el error del servidor manda (no se calcula local)',
        () async {
      adapter.handler = (_) => errorBody(409, 'SERVICE_INACTIVE', 'Inactivo');
      expect(leftOf(await repository.getAvailableSlots(query)),
          isA<ServiceInactiveFailure>());
    });
  });

  group('recordatorios', () {
    test('próximas (local): sin canceladas, completadas, pasadas ni ya '
        'recordadas; ordenadas', () async {
      String iso(Duration fromNow) =>
          BusinessTimeZone.toInstant(now.add(fromNow)).toIso8601String();
      for (final json in [
        backendAppointment(id: 'confirmada', date: iso(const Duration(hours: 5)), status: 'CONFIRMED'),
        backendAppointment(id: 'pendiente', date: iso(const Duration(hours: 2))),
        backendAppointment(id: 'cancelada', date: iso(const Duration(hours: 3)), status: 'CANCELLED'),
        backendAppointment(id: 'completada', date: iso(const Duration(hours: 4)), status: 'COMPLETED'),
        backendAppointment(id: 'recordada', date: iso(const Duration(hours: 6)), reminderSent: true),
        backendAppointment(id: 'pasada', date: iso(const Duration(hours: -1))),
        backendAppointment(id: 'lejana', date: iso(const Duration(days: 8))),
      ]) {
        await seed(json);
      }
      final upcoming = rightOf(await GetUpcomingAppointmentsUseCase(repository,
          now: () => now)(NoParams()));
      expect(upcoming.map((a) => a.id), ['pendiente', 'confirmada']);
    });

    test('send-reminder → teléfono por la cita (no por nombre)', () async {
      adapter.handler = (_) => jsonBody(201, {
            'appointmentId': 'apt-1',
            'clientId': 'cli-1',
            'phone': '3001234567',
            'message': 'Hola Ana',
            'whatsappUrl': 'https://wa.me/573001234567?text=Hola%20Ana',
          });
      final reminder =
          rightOf(await PrepareReminderUseCase(repository)('apt-1'));
      expect(reminder.phone, '3001234567');
      expect(reminder.message, 'Hola Ana');
      final request = adapter.requests.single;
      expect('${request.method} ${request.uri.path}',
          'POST /api/appointments/apt-1/send-reminder');
    });

    test('send-reminder 409 CONFLICT → ReminderUnavailableFailure con el motivo',
        () async {
      adapter.handler = (_) => errorBody(
          409, 'CONFLICT', 'El cliente no tiene número de teléfono registrado');
      final failure = leftOf(await PrepareReminderUseCase(repository)('apt-1'));
      expect(failure, isA<ReminderUnavailableFailure>());
      expect(failure!.message,
          'El cliente no tiene número de teléfono registrado');
    });

    test('mark-sent → hora del primer envío', () async {
      adapter.handler = (_) => jsonBody(200, {
            'success': true,
            'message': 'Recordatorio marcado como enviado',
            'appointmentId': 'apt-1',
            'sentAt': '2026-11-01T09:00:00.000-05:00',
          });
      await seed(backendAppointment());
      expect(rightOf(await MarkReminderSentUseCase(repository)('apt-1')),
          BusinessTimeZone.toWallClock(DateTime.parse('2026-11-01T14:00:00Z')));
      expect(rightOf(await repository.getAppointment('apt-1')).reminderSent,
          true, reason: 'queda también en local');
      final request = adapter.requests.single;
      expect('${request.method} ${request.uri.path}',
          'PATCH /api/appointments/apt-1/reminder/mark-sent');
    });
  });

  group('AppointmentEntity (reglas puras)', () {
    AppointmentEntity withStates(String status, String payment) => entityOf(
        backendAppointment(status: status, paymentStatus: payment));

    test('cancelar: pendiente o confirmada y sin nada pagado', () {
      expect(withStates('PENDING', 'PENDING').canCancel, true);
      expect(withStates('CONFIRMED', 'REFUNDED').canCancel, true);
      expect(withStates('CONFIRMED', 'PARTIAL').canCancel, false);
      expect(withStates('CONFIRMED', 'COMPLETED').canCancel, false);
      expect(withStates('COMPLETED', 'PENDING').canCancel, false);
    });

    test('completar (también sin pagar) y pagar', () {
      expect(withStates('PENDING', 'PENDING').canComplete, true);
      expect(withStates('CANCELLED', 'PENDING').canComplete, false);
      expect(withStates('COMPLETED', 'PARTIAL').canBePaid, true);
      expect(withStates('CONFIRMED', 'COMPLETED').canBePaid, false);
      expect(withStates('CANCELLED', 'PENDING').canBePaid, false);
    });

    test('saldo conocido: total, 0 o null con anticipo', () {
      expect(withStates('PENDING', 'PENDING').knownBalanceDue, 45000);
      expect(withStates('CONFIRMED', 'COMPLETED').knownBalanceDue, 0);
      expect(withStates('CONFIRMED', 'PARTIAL').knownBalanceDue, isNull);
      expect(withStates('CONFIRMED', 'REFUNDED').knownBalanceDue, 45000);
    });

    test('igualdad por valor y copyWith', () {
      final a = withStates('PENDING', 'PENDING');
      expect(a, withStates('PENDING', 'PENDING'));
      expect(a.hashCode, withStates('PENDING', 'PENDING').hashCode);
      final b = a.copyWith(status: AppointmentStatus.CONFIRMED);
      expect(b, isNot(a));
      expect(b.status, AppointmentStatus.CONFIRMED);
      expect(b.services, a.services);
    });
  });
}
