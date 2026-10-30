import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
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

void main() {
  late FakeHttpClientAdapter adapter;
  late AppointmentsRepositoryImpl repository;

  setUp(() {
    adapter = FakeHttpClientAdapter((_) => jsonBody(200, backendAppointment()));
    final dio = buildApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: MemoryTokenStore('jwt'),
      httpClientAdapter: adapter,
      retryDelay: (_) => Duration.zero,
      enableLogs: false,
    );
    repository =
        AppointmentsRepositoryImpl(AppointmentsRemoteDataSourceImpl(dio));
  });

  group('leer', () {
    test(
        'GET /appointments: token del núcleo, sin tenant-id, rango filtrado aquí '
        '(el backend lo ignora) y ordenado', () async {
      adapter.handler = (_) => jsonBody(200, [
            backendAppointment(id: 'tarde', date: '2026-11-03T15:00:00Z'),
            backendAppointment(id: 'fuera', date: '2026-11-05T15:00:00Z'),
            backendAppointment(id: 'temprano', date: '2026-11-03T13:00:00Z'),
          ]);
      final range = AppointmentsRange(
          start: DateTime.utc(2026, 11, 3), end: DateTime.utc(2026, 11, 4));

      final list =
          rightOf(await GetAppointmentsUseCase(repository)(range));

      expect(list.map((a) => a.id), ['temprano', 'tarde']);
      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/appointments');
      expect(request.headers['Authorization'], 'Bearer jwt');
      expect(request.headers.containsKey('tenant-id'), false);
      expect(request.uri.queryParameters, {
        'startDate': '2026-11-03T00:00:00.000Z',
        'endDate': '2026-11-04T00:00:00.000Z',
      });
    });

    test('rango invertido → failure sin llamar al backend', () async {
      final failure = leftOf(await GetAppointmentsUseCase(repository)(
          AppointmentsRange(start: now, end: now.subtract(const Duration(days: 1)))));
      expect(failure, isA<InvalidAppointmentDataFailure>());
      expect(adapter.requests, isEmpty);
    });

    test('GET /appointments/:id; ajena → NotFoundFailure', () async {
      expect(rightOf(await GetAppointmentUseCase(repository)('apt-1')).id,
          'apt-1');
      expect(adapter.requests.single.uri.path, '/api/appointments/apt-1');

      adapter.handler =
          (_) => errorBody(404, 'NOT_FOUND', 'Cita con ID x no encontrada');
      expect(leftOf(await repository.getAppointment('x')),
          isA<NotFoundFailure>());
    });

    test('respuesta que no es una cita → ServerFailure (no TypeError)',
        () async {
      adapter.handler = (_) => jsonBody(200, [
            {'id': 'sin-fecha'}
          ]);
      expect(
          leftOf(await repository.getAppointments(
              AppointmentsRange(start: now, end: now))),
          isA<ServerFailure>());
    });
  });

  group('crear', () {
    final newAppointment = NewAppointment(
      clientId: ' cli-1 ',
      professionalId: 'pro-1',
      serviceIds: const ['svc-1', 'svc-2'],
      start: DateTime.utc(2026, 11, 3, 15),
      notes: '  ',
    );

    CreateAppointmentUseCase create() =>
        CreateAppointmentUseCase(repository, now: () => now);

    test('201: POST /appointments con el DTO limpio y la cita del backend',
        () async {
      adapter.handler = (_) => jsonBody(201, backendAppointment());
      final created = rightOf(await create()(newAppointment));
      expect(created.id, 'apt-1');

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/appointments');
      expect(bodyOf(request), {
        'client_id': 'cli-1',
        'professional_id': 'pro-1',
        'service_ids': ['svc-1', 'svc-2'],
        'date': '2026-11-03T15:00:00.000Z',
      });
    });

    test('reglas locales: sin servicios, repetidos, en el pasado → sin red',
        () async {
      Future<Failure?> failureOf(NewAppointment a) async =>
          leftOf(await create()(a));

      expect(
          (await failureOf(NewAppointment(
                  clientId: 'c', professionalId: 'p', serviceIds: const [],
                  start: DateTime.utc(2027))))!
              .message,
          AppointmentRules.noServicesMessage);
      expect(
          (await failureOf(NewAppointment(
                  clientId: 'c', professionalId: 'p',
                  serviceIds: const ['s', 's'], start: DateTime.utc(2027))))!
              .message,
          AppointmentRules.repeatedServicesMessage);
      expect(
          await failureOf(NewAppointment(
              clientId: 'c', professionalId: 'p', serviceIds: const ['s'],
              start: now.subtract(const Duration(minutes: 1)))),
          isA<AppointmentInPastFailure>());
      expect(adapter.requests, isEmpty);
    });

    // HTTP legado 400 (D-11): se decide por `code`.
    for (final (code, type) in [
      ('SLOT_UNAVAILABLE', SlotUnavailableFailure),
      ('PROFESSIONAL_INACTIVE', ProfessionalInactiveFailure),
      ('APPOINTMENT_IN_PAST', AppointmentInPastFailure),
      ('TRIAL_LIMIT_REACHED', TrialLimitReachedFailure),
      ('SUBSCRIPTION_INACTIVE', SubscriptionInactiveFailure),
    ]) {
      test('400 $code → $type con el texto del backend', () async {
        adapter.handler = (_) => errorBody(400, code, 'Texto de $code');
        final failure = leftOf(await create()(newAppointment));
        expect(failure.runtimeType, type);
        expect(failure!.message, 'Texto de $code');
        expect(failure.code, code);
        expect(failure.statusCode, 400);
      });
    }

    for (final (code, type) in [
      ('SERVICE_NOT_OFFERED_BY_PROFESSIONAL', ServiceNotOfferedFailure),
      ('OUTSIDE_BUSINESS_HOURS', OutsideBusinessHoursFailure),
    ]) {
      test('409 $code → $type (7.03, 8.01)', () async {
        adapter.handler = (_) => errorBody(409, code, 'Texto de $code');
        final failure = leftOf(await create()(newAppointment));
        expect(failure.runtimeType, type);
        expect(failure, isA<ConflictFailure>());
        expect(failure!.message, 'Texto de $code');
      });
    }

    test('HTTP definitivo (409/402) → mismo failure', () async {
      adapter.handler =
          (_) => errorBody(409, 'SLOT_UNAVAILABLE', 'Horario no disponible');
      expect(leftOf(await create()(newAppointment)),
          isA<SlotUnavailableFailure>());
      adapter.handler = (_) => errorBody(402, 'TRIAL_LIMIT_REACHED', 'Límite');
      expect(leftOf(await create()(newAppointment)),
          isA<TrialLimitReachedFailure>());
    });

    test('403 (Employee para otro profesional) → ForbiddenFailure', () async {
      adapter.handler = (_) => errorBody(403, 'FORBIDDEN', 'Solo para ti');
      expect(leftOf(await create()(newAppointment)), isA<ForbiddenFailure>());
    });

    test('4xx con cuerpo HTML → failure por HTTP, sin TypeError', () async {
      adapter.handler = (_) => textBody(400, '<html>Bad Request</html>');
      expect(leftOf(await create()(newAppointment)), isA<ValidationFailure>());
    });

    test('red: POST no se reintenta (no duplica citas) → NetworkFailure',
        () async {
      adapter.handler = connectionError;
      expect(leftOf(await create()(newAppointment)), isA<NetworkFailure>());
      expect(adapter.requests, hasLength(1));
    });

    test('500 → ServerFailure', () async {
      adapter.handler =
          (_) => errorBody(500, 'INTERNAL_ERROR', 'detalle interno');
      expect(leftOf(await create()(newAppointment)), isA<ServerFailure>());
    });
  });

  group('editar', () {
    final original = entityOf(backendAppointment(
      date: '2026-11-03T15:00:00Z',
      services: [backendService(), backendService(id: 'svc-2', name: 'Barba')],
    ));

    UpdateAppointmentUseCase update() =>
        UpdateAppointmentUseCase(repository, now: () => now);

    test('PATCH solo con lo que cambió', () async {
      final changes = AppointmentChanges.between(
        original,
        clientId: 'cli-1',
        professionalId: 'pro-1',
        serviceIds: const ['svc-2', 'svc-1'], // mismo conjunto
        start: DateTime.utc(2026, 11, 3, 15), // mismo instante
        notes: ' Con prisa ',
      );
      rightOf(await update()(
          UpdateAppointmentParams(original: original, changes: changes)));

      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.uri.path, '/api/appointments/apt-1');
      expect(bodyOf(request), {'notes': 'Con prisa'});
    });

    test('sin cambios → devuelve la original sin llamar al backend', () async {
      final result = await update()(UpdateAppointmentParams(
        original: original,
        changes: AppointmentChanges.between(original,
            professionalId: 'pro-1', notes: 'Sin prisa'),
      ));
      expect(rightOf(result), same(original));
      expect(adapter.requests, isEmpty);
    });

    test(
        'carrera de editar: dos formularios abiertos sobre la misma cita no se '
        'pisan (cada PATCH lleva solo su campo)', () async {
      final moved = AppointmentChanges.between(original,
          start: DateTime.utc(2026, 11, 4, 15), notes: 'Sin prisa');
      final otherProfessional = AppointmentChanges.between(original,
          professionalId: 'pro-2', start: original.startTime);

      await update()(UpdateAppointmentParams(original: original, changes: moved));
      await update()(UpdateAppointmentParams(
          original: original, changes: otherProfessional));

      expect(adapter.requests.map(bodyOf), [
        {'date': '2026-11-04T15:00:00.000Z'},
        {'professional_id': 'pro-2'},
      ]);
    });

    test('mover al pasado → AppointmentInPastFailure sin red', () async {
      final failure = leftOf(await update()(UpdateAppointmentParams(
        original: original,
        changes: AppointmentChanges(start: now.subtract(const Duration(hours: 1))),
      )));
      expect(failure, isA<AppointmentInPastFailure>());
      expect(adapter.requests, isEmpty);
    });

    test('dejar sin servicios → failure sin red', () async {
      final failure = leftOf(await update()(UpdateAppointmentParams(
          original: original,
          changes: AppointmentChanges.between(original, serviceIds: const []))));
      expect(failure, isA<InvalidAppointmentDataFailure>());
      expect(adapter.requests, isEmpty);
    });

    test('400 SLOT_UNAVAILABLE / PROFESSIONAL_INACTIVE al mover', () async {
      final changes = AppointmentChanges(start: DateTime.utc(2026, 11, 5, 15));
      adapter.handler =
          (_) => errorBody(400, 'SLOT_UNAVAILABLE', 'Horario no disponible');
      expect(
          leftOf(await update()(
              UpdateAppointmentParams(original: original, changes: changes))),
          isA<SlotUnavailableFailure>());
      adapter.handler = (_) =>
          errorBody(400, 'PROFESSIONAL_INACTIVE', 'Profesional inactivo');
      expect(
          leftOf(await update()(
              UpdateAppointmentParams(original: original, changes: changes))),
          isA<ProfessionalInactiveFailure>());
    });
  });

  group('cancelar y completar', () {
    test('PATCH :id/cancel con el motivo; sin motivo, cuerpo vacío', () async {
      adapter.handler =
          (_) => jsonBody(200, backendAppointment(status: 'CANCELLED'));
      final cancel = CancelAppointmentUseCase(repository);

      final cancelled = rightOf(await cancel(const CancelAppointmentParams(
          appointmentId: 'apt-1', reason: ' No viene ')));
      expect(cancelled.status, AppointmentStatus.CANCELLED);
      await cancel(const CancelAppointmentParams(appointmentId: 'apt-1'));

      expect(adapter.requests.map((r) => '${r.method} ${r.uri.path}'),
          everyElement('PATCH /api/appointments/apt-1/cancel'));
      expect(bodyOf(adapter.requests.first),
          {'cancellation_reason': 'No viene'});
      expect(bodyOf(adapter.requests.last), isEmpty);
    });

    test('motivo de más de 500 caracteres → failure sin red', () async {
      final failure = leftOf(await CancelAppointmentUseCase(repository)(
          CancelAppointmentParams(appointmentId: 'a', reason: 'x' * 501)));
      expect(failure, isA<InvalidAppointmentDataFailure>());
      expect(adapter.requests, isEmpty);
    });

    test('409 APPOINTMENT_PAID (con un anticipo) → AppointmentPaidFailure',
        () async {
      adapter.handler = (_) => errorBody(409, 'APPOINTMENT_PAID',
          'La cita tiene pagos registrados: reembólsalos por completo antes de cancelarla');
      final failure = leftOf(await CancelAppointmentUseCase(repository)(
          const CancelAppointmentParams(appointmentId: 'apt-1')));
      expect(failure, isA<AppointmentPaidFailure>());
      expect(failure, isA<ConflictFailure>());
      expect(failure!.message, startsWith('La cita tiene pagos'));
    });

    test('completar antes de empezar → AppointmentNotStartedFailure (7.03)',
        () async {
      adapter.handler = (_) => errorBody(409, 'APPOINTMENT_NOT_STARTED',
          'No se puede completar una cita que aún no ha empezado');
      final failure =
          leftOf(await CompleteAppointmentUseCase(repository)('apt-1'));
      expect(failure, isA<AppointmentNotStartedFailure>());
      expect(failure!.message,
          'No se puede completar una cita que aún no ha empezado');
    });

    test('PATCH :id/complete; ya cancelada → InvalidStateTransitionFailure',
        () async {
      adapter.handler =
          (_) => jsonBody(200, backendAppointment(status: 'COMPLETED'));
      final complete = CompleteAppointmentUseCase(repository);
      expect(rightOf(await complete('apt-1')).status,
          AppointmentStatus.COMPLETED);
      final request = adapter.requests.single;
      expect('${request.method} ${request.uri.path}',
          'PATCH /api/appointments/apt-1/complete');

      adapter.handler = (_) => errorBody(409, 'INVALID_STATE_TRANSITION',
          'No se puede pasar una cita cancelada a completada');
      final failure = leftOf(await complete('apt-1'));
      expect(failure, isA<InvalidStateTransitionFailure>());
      expect(failure!.message, contains('cancelada'));
    });
  });

  group('horas libres', () {
    final query = AvailableSlotsQuery(
      professionalId: 'pro-1',
      day: DateTime(2026, 11, 3),
      serviceIds: const ['svc-1', 'svc-2'],
      stepMinutes: 30,
    );

    test('GET available-slots con día del negocio → instantes', () async {
      adapter.handler = (_) => jsonBody(200,
          ['2026-11-03T09:00:00.000-05:00', '2026-11-03T09:30:00.000-05:00']);
      final slots = rightOf(await GetAvailableSlotsUseCase(repository)(query));
      expect(slots, [
        BusinessTimeZone.toWallClock(DateTime.parse('2026-11-03T14:00:00Z')),
        BusinessTimeZone.toWallClock(DateTime.parse('2026-11-03T14:30:00Z')),
      ]);
      final request = adapter.requests.single;
      expect(request.uri.path, '/api/appointments/available-slots');
      expect(request.uri.queryParameters, {
        'professional_id': 'pro-1',
        'date': '2026-11-03',
        'service_ids': 'svc-1,svc-2',
        'step': '30',
      });
    });

    test('sin servicios o paso fuera de rango → failure sin red', () async {
      final slots = GetAvailableSlotsUseCase(repository);
      expect(
          leftOf(await slots(AvailableSlotsQuery(
              professionalId: 'p', day: now, serviceIds: const []))),
          isA<InvalidAppointmentDataFailure>());
      expect(
          leftOf(await slots(AvailableSlotsQuery(
              professionalId: 'p',
              day: now,
              serviceIds: const ['s'],
              stepMinutes: 1))),
          isA<InvalidAppointmentDataFailure>());
      expect(adapter.requests, isEmpty);
    });

    test('PROFESSIONAL_INACTIVE y 403 del Employee', () async {
      adapter.handler =
          (_) => errorBody(400, 'PROFESSIONAL_INACTIVE', 'Inactivo');
      expect(leftOf(await GetAvailableSlotsUseCase(repository)(query)),
          isA<ProfessionalInactiveFailure>());
      adapter.handler = (_) => errorBody(403, 'FORBIDDEN', 'Solo tu agenda');
      expect(leftOf(await GetAvailableSlotsUseCase(repository)(query)),
          isA<ForbiddenFailure>());
    });

    test('red en un GET: se reintenta y acaba en NetworkFailure', () async {
      adapter.handler = connectionError;
      expect(leftOf(await GetAvailableSlotsUseCase(repository)(query)),
          isA<NetworkFailure>());
      expect(adapter.requests.length, greaterThan(1));
    });
  });

  group('recordatorios', () {
    test('próximas: sin canceladas, completadas, pasadas ni ya recordadas; '
        'ordenadas', () async {
      String iso(Duration fromNow) =>
          BusinessTimeZone.toInstant(now.add(fromNow)).toIso8601String();
      adapter.handler = (_) => jsonBody(200, [
            backendAppointment(id: 'confirmada', date: iso(const Duration(hours: 5)), status: 'CONFIRMED'),
            backendAppointment(id: 'pendiente', date: iso(const Duration(hours: 2))),
            backendAppointment(id: 'cancelada', date: iso(const Duration(hours: 3)), status: 'CANCELLED'),
            backendAppointment(id: 'completada', date: iso(const Duration(hours: 4)), status: 'COMPLETED'),
            backendAppointment(id: 'recordada', date: iso(const Duration(hours: 6)), reminderSent: true),
            backendAppointment(id: 'pasada', date: iso(const Duration(hours: -1))),
            backendAppointment(id: 'lejana', date: iso(const Duration(days: 8))),
          ]);
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
      expect(rightOf(await MarkReminderSentUseCase(repository)('apt-1')),
          BusinessTimeZone.toWallClock(DateTime.parse('2026-11-01T14:00:00Z')));
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
