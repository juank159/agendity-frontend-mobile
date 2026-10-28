import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/services/notification_service.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_changes.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_upcoming_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/mark_reminder_sent_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/prepare_reminder_usecase.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_reminder_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_calendar_data_source.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_detail_dialog.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_limits_usecase.dart';

import 'appointment_model_test.dart' show backendAppointment;

/// El negocio pasó de Bogotá (UTC-5) a Caracas (UTC-4) y el teléfono está en
/// una tercera zona (correr también con `TZ=Asia/Tokyo`). Decisión de 6.05:
/// toda cita se pinta en la zona ACTUAL del negocio, según su instante.
class _Repo implements AppointmentsRepository {
  List<AppointmentEntity> result = const [];

  @override
  Future<Either<Failure, List<AppointmentEntity>>> getAppointments(
          AppointmentsRange range) async =>
      Right(result);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SubscriptionRepo implements SubscriptionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notifications implements NotificationService {
  final scheduledAt = <DateTime>[];

  @override
  Future<void> scheduleAppointmentReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async =>
      scheduledAt.add(scheduledTime);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AppointmentEntity read(Map<String, dynamic> json) =>
    AppointmentModel.fromJson(json).toEntity();

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    Get.testMode = true;
    BusinessTimeZone.use('America/Caracas');
    // 2026-11-03 12:00Z = 08:00 en Caracas.
    BusinessTimeZone.clock = () => DateTime.utc(2026, 11, 3, 12);
  });

  tearDown(() {
    Get.reset();
    BusinessTimeZone.reset();
    BusinessTimeZone.clock = DateTime.now;
  });

  // 10:00 de Bogotá = 15:00Z = 11:00 de Caracas.
  AppointmentEntity fromBogota({String id = 'bog'}) => read(backendAppointment(
      id: id,
      date: '2026-11-03T10:00:00.000-05:00',
      timeZone: 'America/Bogota'));

  // 10:30 de Caracas = 14:30Z: es ANTES que la de Bogotá, aunque su hora
  // de pared guardada (10:30) sea mayor que 10:00.
  AppointmentEntity fromCaracas() => read(backendAppointment(
      id: 'car',
      date: '2026-11-03T10:30:00.000-04:00',
      timeZone: 'America/Caracas'));

  test('1. el aviso local se programa en el instante real de la cita',
      () async {
    final repo = _Repo()..result = [fromBogota()];
    final notifications = _Notifications();
    final controller = AppointmentReminderController(
      getUpcomingAppointmentsUseCase: GetUpcomingAppointmentsUseCase(repo),
      prepareReminderUseCase: PrepareReminderUseCase(repo),
      markReminderSentUseCase: MarkReminderSentUseCase(repo),
      notifications: () => notifications,
      openLink: (_) async => true,
    );
    await controller.fetch();
    expect(notifications.scheduledAt, [
      DateTime.utc(2026, 11, 3, 15)
          .subtract(AppointmentReminderController.localNoticeLead)
    ]);
    // Leído en Caracas: 10:30, no 09:30 (una hora antes).
    expect(BusinessTimeZone.toWallClock(notifications.scheduledAt.single),
        DateTime(2026, 11, 3, 10, 30));
  });

  group('2. agenda: rango y orden por instante', () {
    late AppointmentsController agenda;

    setUp(() async {
      agenda = AppointmentsController(
        getAppointmentsUseCase: GetAppointmentsUseCase(_Repo()),
        checkSubscriptionLimitsUseCase:
            CheckSubscriptionLimitsUseCase(_SubscriptionRepo()),
      )..onInit(); // día de hoy en Caracas: 3 de noviembre
      await Future<void>.delayed(Duration.zero);
    });

    test('ordena por instante, no por la hora guardada', () {
      agenda
        ..applyChange(fromBogota())
        ..applyChange(fromCaracas());
      expect(agenda.appointments.map((a) => a.id), ['car', 'bog']);
    });

    test('una cita del 3 en Bogotá que cae el 4 en Caracas no se pinta el 3',
        () {
      // 23:30 del 3 en Bogotá = 04:30Z del 4 = 00:30 del 4 en Caracas.
      final tardia = read(backendAppointment(
          id: 'tarde',
          date: '2026-11-03T23:30:00.000-05:00',
          timeZone: 'America/Bogota'));
      agenda.applyChange(tardia);
      expect(agenda.appointments, isEmpty);
      expect(tardia.startTime, DateTime(2026, 11, 4, 0, 30));
    });
  });

  group('3. toda cita en la zona actual del negocio', () {
    test('calendario: el bloque ocupa las 11:00 de Caracas', () {
      final source = AppointmentCalendarDataSource([fromBogota()]);
      expect(source.getStartTime(0), DateTime(2026, 11, 3, 11));
      expect(fromBogota().endTime, DateTime(2026, 11, 3, 11, 45));
    });

    test('detalle: nota con la hora en la que se agendó', () {
      expect(recordedZoneNote(fromBogota()),
          'Agendada en hora de Bogota: ${formatTime(DateTime(2026, 11, 3, 10))}');
      expect(recordedZoneNote(fromCaracas()), isNull);
    });

    test('editar sin tocar la hora no mueve la cita', () {
      final appointment = fromBogota();
      // El formulario abre con startTime (11:00 de Caracas).
      expect(
          AppointmentChanges.between(appointment,
                  start: appointment.startTime, notes: 'Otra nota')
              .start,
          isNull);
      // Elegir las 10:00 (de Caracas) sí la mueve: 14:00Z.
      final moved = AppointmentChanges.between(appointment,
          start: DateTime(2026, 11, 3, 10));
      expect(AppointmentChangesModel.toJson(moved)['date'],
          '2026-11-03T14:00:00.000Z');
    });

    test('si el negocio vuelve a Bogotá, la misma entidad se ve a las 10:00',
        () {
      final appointment = fromBogota();
      BusinessTimeZone.use('America/Bogota');
      expect(appointment.startTime, DateTime(2026, 11, 3, 10));
      expect(appointment.isInOtherTimeZone, isFalse);
      expect(recordedZoneNote(appointment), isNull);
    });
  });
}
