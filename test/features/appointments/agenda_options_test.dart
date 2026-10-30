import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_tile.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_limits_usecase.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Agenda (7.04-2, 6 y 7; 9.03): bloques cortos sin overflow, canceladas sin
/// columnas, la cita nueva en el día visible y la marca de reserva web.
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

AppointmentEntity appointment(String id,
        {AppointmentStatus status = AppointmentStatus.PENDING,
        AppointmentSource source = AppointmentSource.APP,
        int minutes = 60,
        DateTime? start}) {
  final begin = start ?? DateTime(2030, 1, 7, 10);
  return AppointmentEntity(
    id: id,
    client: const AppointmentClient(id: 'c1', name: 'Carla', lastname: 'Díaz'),
    professionalId: 'e1',
    services: [
      AppointmentServiceLine(
          serviceId: 's1',
          name: 'Diseño de cejas',
          durationMinutes: minutes,
          price: 30000),
    ],
    startTime: begin,
    endTime: begin.add(Duration(minutes: minutes)),
    status: status,
    totalPrice: 30000,
    source: source,
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() {
    Get.reset();
    BusinessTimeZone.reset();
    BusinessTimeZone.clock = DateTime.now;
  });

  AppointmentsController agenda({DateTime Function()? now}) =>
      AppointmentsController(
        getAppointmentsUseCase: GetAppointmentsUseCase(_Repo()),
        checkSubscriptionLimitsUseCase:
            CheckSubscriptionLimitsUseCase(_SubscriptionRepo()),
        now: now,
      );

  group('canceladas (7.04-7)', () {
    test('no se pintan salvo que se pidan; el contador las sigue', () {
      final c = agenda(now: () => DateTime(2030, 1, 7, 8))
        ..appointments.assignAll([
          appointment('a'),
          appointment('b', status: AppointmentStatus.CANCELLED),
        ]);
      expect(c.visibleAppointments.map((a) => a.id), ['a']);
      expect(c.countOn(DateTime(2030, 1, 7)), 1);
      c.toggleShowCancelled();
      expect(c.visibleAppointments.map((a) => a.id), ['a', 'b']);
      expect(c.countOn(DateTime(2030, 1, 7)), 2);
    });
  });

  group('cita nueva desde "+" (7.04-6)', () {
    test('hoy visible: ahora', () {
      final now = DateTime(2030, 1, 7, 8, 15);
      expect(agenda(now: () => now).newAppointmentStart, now);
    });

    test('otro día visible: ese día, no hoy', () async {
      final c = agenda(now: () => DateTime(2030, 1, 7, 8, 15));
      await c.changeView(CalendarView.day, targetDate: DateTime(2030, 1, 9, 12));
      expect(c.newAppointmentStart, DateTime(2030, 1, 9));
    });
  });

  group('bloque de la agenda', () {
    Future<void> pumpTile(WidgetTester tester, AppointmentEntity a,
        {double height = 33}) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeConfig.lightTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
                width: 220,
                height: height,
                child: AppointmentTile(appointment: a)),
          ),
        ),
      ));
    }

    testWidgets('15 min: una sola línea, sin overflow (7.04-2)',
        (tester) async {
      // 15 min = 35 px en la agenda (70 px por media hora) menos 2 de margen.
      await pumpTile(tester, appointment('a', minutes: 15));
      expect(tester.takeException(), isNull);
      expect(find.text('Carla Díaz · Diseño de cejas'), findsOneWidget);
    });

    testWidgets('bloque alto: cliente y servicio en dos líneas',
        (tester) async {
      await pumpTile(tester, appointment('a'), height: 70);
      expect(find.text('Carla Díaz'), findsOneWidget);
      expect(find.text('Diseño de cejas'), findsOneWidget);
    });

    testWidgets('reserva web: lleva la marca (9.03)', (tester) async {
      await pumpTile(
          tester, appointment('a', source: AppointmentSource.WEB),
          height: 70);
      expect(find.bySemanticsLabel(RegExp('reserva web')), findsWidgets);
      expect(find.byIcon(Icons.public), findsOneWidget);
    });
  });
}
