import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_changes.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';
import 'package:login_signup/features/appointments/domain/usecases/create_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_upcoming_appointments_usecase.dart';

import 'appointment_model_test.dart' show backendAppointment;
import 'appointments_repository_test.dart' show leftOf;
import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';

/// Dos negocios, Bogotá (UTC−5) y Caracas (UTC−4), con el teléfono en
/// cualquier zona (D-15). Correr también con `TZ=Asia/Tokyo` y
/// `TZ=America/Bogota`: el resultado no depende del dispositivo.
void main() {
  tearDown(() {
    BusinessTimeZone.reset();
    BusinessTimeZone.clock = DateTime.now;
  });

  AppointmentEntity read(Map<String, dynamic> json) =>
      AppointmentModel.fromJson(json).toEntity();

  group('el mismo instante en dos negocios', () {
    // 2026-11-03 15:00Z = 10:00 en Bogotá = 11:00 en Caracas.
    test('Bogotá ve las 10:00 y Caracas las 11:00', () {
      BusinessTimeZone.use('America/Bogota');
      final bogota = read(backendAppointment(
          date: '2026-11-03T10:00:00.000-05:00', timeZone: 'America/Bogota'));
      expect(bogota.startTime, DateTime(2026, 11, 3, 10));
      expect(bogota.endTime, DateTime(2026, 11, 3, 10, 45));

      BusinessTimeZone.use('America/Caracas');
      final caracas = read(backendAppointment(
          date: '2026-11-03T11:00:00.000-04:00', timeZone: 'America/Caracas'));
      expect(caracas.startTime, DateTime(2026, 11, 3, 11));
      expect(caracas.startInstant, bogota.startInstant);
    });

    test('agendar las 11:00 en Caracas envía las 15:00Z (no las 16:00Z)',
        () {
      BusinessTimeZone.use('America/Caracas');
      final body = NewAppointmentModel.toJson(NewAppointment(
        clientId: 'cli-1',
        professionalId: 'pro-1',
        serviceIds: const ['svc-1'],
        start: DateTime(2026, 11, 3, 11),
      ));
      expect(body['date'], '2026-11-03T15:00:00.000Z');
    });

    test('día de huecos libres y rango: el calendario del negocio', () async {
      BusinessTimeZone.use('America/Caracas');
      final adapter = FakeHttpClientAdapter((_) => jsonBody(200, [
            '2026-11-03T09:00:00.000-04:00',
            '2026-11-03T09:30:00.000-04:00',
          ]));
      final remote = AppointmentsRemoteDataSourceImpl(buildApiClient(
          baseUrl: 'http://api.test/api',
          tokenStore: MemoryTokenStore('jwt'),
          httpClientAdapter: adapter,
          enableLogs: false));
      final slots = await remote.getAvailableSlots(AvailableSlotsQuery(
          professionalId: 'pro-1',
          day: DateTime(2026, 11, 3),
          serviceIds: const ['svc-1']));
      expect(adapter.requests.single.uri.queryParameters['date'], '2026-11-03');
      expect(slots, [DateTime(2026, 11, 3, 9), DateTime(2026, 11, 3, 9, 30)]);

      adapter.handler = (_) => jsonBody(200, <Object>[]);
      await remote.getAppointments(AppointmentsRange.day(DateTime(2026, 11, 3)));
      expect(adapter.requests.last.uri.queryParameters, {
        'startDate': '2026-11-03T04:00:00.000Z',
        'endDate': '2026-11-04T04:00:00.000Z',
      });
    });
  });

  group('cita con su propia zona (el negocio cambió de zona, 6.03)', () {
    setUp(() => BusinessTimeZone.use('America/Caracas'));

    final fromBogota = backendAppointment(
        date: '2026-11-03T10:00:00.000-05:00', timeZone: 'America/Bogota');

    test('se presenta en su zona y guarda la zona en la entidad', () {
      final appointment = read(fromBogota);
      expect(appointment.startTime, DateTime(2026, 11, 3, 10));
      expect(appointment.timeZone, 'America/Bogota');
      expect(appointment.startInstant, DateTime.utc(2026, 11, 3, 15));
      expect(appointment.createdAt, DateTime(2026, 10, 28, 8));
    });

    test('editar sin tocar la hora no la mueve; moverla usa la zona actual',
        () {
      final appointment = read(fromBogota);
      final same = AppointmentChanges.between(appointment,
          start: appointment.startTime, notes: 'Otra nota');
      expect(same.start, isNull);

      final moved = AppointmentChanges.between(appointment,
          start: DateTime(2026, 11, 3, 12));
      expect(AppointmentChangesModel.toJson(moved)['date'],
          '2026-11-03T16:00:00.000Z', reason: '12:00 de Caracas');
    });

    test('rango y recordatorios comparan instantes, no horas de pared', () {
      final appointment = read(fromBogota); // 15:00Z
      // 10:30 en Caracas = 14:30Z: la cita aún no empieza.
      expect(appointment.needsReminderAt(DateTime(2026, 11, 3, 10, 30)), true);
      // 11:30 en Caracas = 15:30Z: ya empezó, aunque su hora de pared sea 10:00.
      expect(appointment.needsReminderAt(DateTime(2026, 11, 3, 11, 30)), false);
      expect(
          AppointmentsRange(
                  start: DateTime(2026, 11, 3, 11),
                  end: DateTime(2026, 11, 3, 12))
              .contains(appointment.startInstant),
          true);
    });
  });

  group('"ahora" del negocio en los use cases', () {
    late FakeHttpClientAdapter adapter;
    late AppointmentsRepositoryImpl repository;

    setUp(() {
      adapter = FakeHttpClientAdapter((_) => jsonBody(201, backendAppointment()));
      repository = AppointmentsRepositoryImpl(AppointmentsRemoteDataSourceImpl(
          buildApiClient(
              baseUrl: 'http://api.test/api',
              tokenStore: MemoryTokenStore('jwt'),
              httpClientAdapter: adapter,
              enableLogs: false)));
      // 2026-11-03 14:30Z: 09:30 en Bogotá, 10:30 en Caracas.
      BusinessTimeZone.clock = () => DateTime.utc(2026, 11, 3, 14, 30);
    });

    NewAppointment at(DateTime start) => NewAppointment(
        clientId: 'cli-1',
        professionalId: 'pro-1',
        serviceIds: const ['svc-1'],
        start: start);

    test('las 10:00 ya pasaron en Caracas pero no en Bogotá', () async {
      BusinessTimeZone.use('America/Caracas');
      expect(
          leftOf(await CreateAppointmentUseCase(repository)(
              at(DateTime(2026, 11, 3, 10)))),
          isA<AppointmentInPastFailure>());
      expect(adapter.requests, isEmpty);

      BusinessTimeZone.use('America/Bogota');
      expect(
          leftOf(await CreateAppointmentUseCase(repository)(
              at(DateTime(2026, 11, 3, 10)))),
          isNull);
      expect(bodyDate(adapter), '2026-11-03T15:00:00.000Z');
    });

    test('próximas: el rango sale del ahora del negocio', () async {
      BusinessTimeZone.use('America/Caracas');
      adapter.handler = (_) => jsonBody(200, [
            backendAppointment(
                id: 'ya-paso', date: '2026-11-03T10:00:00.000-04:00',
                timeZone: 'America/Caracas'),
            backendAppointment(
                id: 'luego', date: '2026-11-03T11:00:00.000-04:00',
                timeZone: 'America/Caracas'),
          ]);
      final result =
          await GetUpcomingAppointmentsUseCase(repository)(NoParams());
      expect(result.getOrElse(() => []).map((a) => a.id), ['luego']);
      expect(adapter.requests.single.uri.queryParameters['startDate'],
          '2026-11-03T14:30:00.000Z');
    });
  });

  test('DateCodec y el teléfono: la hora no depende del dispositivo', () {
    BusinessTimeZone.use('America/Caracas');
    final wall = DateCodec.decode('2026-11-03T15:00:00Z');
    expect(wall, DateTime(2026, 11, 3, 11));
    expect(wall.timeZoneOffset, DateTime(2026, 11, 3).timeZoneOffset,
        reason: 'es un DateTime "local" con los campos del negocio');
  });
}

String? bodyDate(FakeHttpClientAdapter adapter) {
  final data = adapter.requests.last.data;
  return data is Map ? data['date'] as String? : null;
}
