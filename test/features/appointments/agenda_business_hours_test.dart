import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/appointments/domain/usecases/create_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_available_slots_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/update_appointment_usecase.dart';
import 'package:login_signup/features/appointments/presentation/controllers/agenda_slot_finder.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_day_notice.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_slot_sheet.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_calendar.dart';
import 'package:login_signup/features/appointments/presentation/widgets/view_selector_bottom_sheet.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_offered_by_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/repositories/settings_repository.dart';
import 'package:login_signup/features/settings/domain/usecases/get_business_settings_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_limits.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_limits_usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../core/session/memory_token_store.dart';

/// Agenda ajustada al horario del negocio (13.02, D-25): rango por día,
/// zonas no reservables, día cerrado y qué pasa al tocar una hora.

// --- Repositorios falsos -------------------------------------------------

class _Appointments implements AppointmentsRepository {
  List<AppointmentEntity> agenda = [];

  /// Horas libres por profesional (para cualquier servicio).
  Map<String, List<DateTime>> free = {};
  final slotQueries = <AvailableSlotsQuery>[];

  @override
  Future<Either<Failure, List<AppointmentEntity>>> getAppointments(
          AppointmentsRange range) async =>
      Right(List.of(agenda));

  @override
  Future<Either<Failure, List<DateTime>>> getAvailableSlots(
      AvailableSlotsQuery query) async {
    slotQueries.add(query);
    return Right(List.of(free[query.professionalId] ?? const []));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Settings implements SettingsRepository {
  OpeningHours? opening;

  @override
  Future<Either<Failure, BusinessSettings>> getSettings() async => Right(
      BusinessSettings(timeZone: 'America/Bogota', openingHours: opening));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Team implements EmployeesRepository {
  List<EmployeeEntity> team = const [ana, bea];

  @override
  Future<Either<Failure, List<EmployeeEntity>>> getEmployees() async =>
      Right(team);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Services implements ServicesRepository {
  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices() async =>
      const Right([corte, tinte]);

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServicesOfferedBy(
          String professionalId) async =>
      const Right([tinte, corte]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Subscription implements SubscriptionRepository {
  @override
  Future<Either<Failure, SubscriptionLimits>> checkLimits() async =>
      const Right(SubscriptionLimits(canCreateAppointment: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- Datos ------------------------------------------------------------------

const corte = ServiceEntity(
    id: 's1', name: 'Corte', price: 20000, duration: 30, categoryId: 'k');
const tinte = ServiceEntity(
    id: 's2', name: 'Tinte', price: 50000, duration: 60, categoryId: 'k');
const ana = EmployeeEntity(
  id: 'e1',
  name: 'Ana',
  lastname: 'Pérez',
  email: 'ana@mail.com',
  isActive: true,
  isEmailVerified: true,
  schedule: {
    'monday': [WorkHours(start: '09:00', end: '20:00')],
    'tuesday': [WorkHours(start: '09:00', end: '20:00')],
  },
);
const bea = EmployeeEntity(
  id: 'e3',
  name: 'Bea',
  lastname: 'Soto',
  email: 'bea@mail.com',
  isActive: true,
  isEmailVerified: true,
  schedule: {'monday': [WorkHours(start: '12:00', end: '16:00')]},
);

/// Lunes a sábado de 9:00 a. m. a 8:00 p. m.; domingo cerrado.
OpeningHours nineToEight() => OpeningHours([
      for (var d = 1; d <= 6; d++)
        OpeningHoursRange(
            dayOfWeek: d, hours: const WorkHours(start: '09:00', end: '20:00')),
    ]);

/// Lunes de 9 a 13 y de 15 a 19.
OpeningHours splitMonday() => OpeningHours(const [
      OpeningHoursRange(
          dayOfWeek: 1, hours: WorkHours(start: '09:00', end: '13:00')),
      OpeningHoursRange(
          dayOfWeek: 1, hours: WorkHours(start: '15:00', end: '19:00')),
    ]);

final monday = DateTime(2030, 1, 7);
final sunday = DateTime(2030, 1, 13);

void main() {
  late _Appointments appts;
  late _Settings settings;
  late _Team team;

  setUpAll(() => initializeDateFormatting('es'));

  void signInAs(String role, {String userId = 'o1', String name = 'Olga'}) {
    final store = MemoryTokenStore();
    final session = SessionController(SessionService(
      tokenStore: store,
      repository: SessionRepository(store),
    ));
    session.session.value =
        Session(token: 't', userId: userId, name: name, roles: [role]);
    Get.put<SessionController>(session, permanent: true);
  }

  setUp(() {
    Get.testMode = true;
    appts = _Appointments();
    settings = _Settings()..opening = nineToEight();
    team = _Team();
    // Lunes 7 de enero de 2030, 8:00 a. m. en el negocio.
    BusinessTimeZone.clock =
        () => BusinessTimeZone.toInstant(DateTime(2030, 1, 7, 8));
    // Como los `<feature>_dependencies` (el formulario los busca).
    Get.put(CreateAppointmentUseCase(appts));
    Get.put(UpdateAppointmentUseCase(appts));
    Get.put(GetAvailableSlotsUseCase(appts));
    Get.put(GetServicesUseCase(_Services()));
    Get.put(GetServicesOfferedByUseCase(_Services()));
    Get.put(GetEmployeesUseCase(team));
  });

  tearDown(() {
    Get.reset();
    BusinessTimeZone.clock = DateTime.now;
  });

  AppointmentsController agenda() => Get.put(AppointmentsController(
        getAppointmentsUseCase: GetAppointmentsUseCase(appts),
        checkSubscriptionLimitsUseCase:
            CheckSubscriptionLimitsUseCase(_Subscription()),
        getBusinessSettingsUseCase: GetBusinessSettingsUseCase(settings),
        getEmployeesUseCase: GetEmployeesUseCase(team),
        slotFinder: AgendaSlotFinder(
          getAvailableSlotsUseCase: GetAvailableSlotsUseCase(appts),
          getServicesOfferedByUseCase: GetServicesOfferedByUseCase(_Services()),
        ),
        now: BusinessTimeZone.now,
      ));

  Future<AppointmentsController> pumpAgenda(WidgetTester tester,
      {DateTime? day}) async {
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    if (!Get.isRegistered<SessionController>()) signInAs('Owner');
    final c = agenda();
    await tester.pumpWidget(GetMaterialApp(
      theme: ThemeConfig.lightTheme,
      home: const Scaffold(body: AppointmentCalendar()),
    ));
    await tester.pumpAndSettle();
    if (day != null) {
      await c.showDay(day);
      await tester.pumpAndSettle();
    }
    return c;
  }

  SfCalendar calendar(WidgetTester tester) =>
      tester.widget<SfCalendar>(find.byType(SfCalendar));

  /// Toca la celda de [hour]:[minute] en la vista de día (cada media hora
  /// mide 70 px y la columna de horas, 70).
  Future<void> tapCell(WidgetTester tester, int hour, int minute) async {
    final rect = tester.getRect(find.byType(SfCalendar));
    final start = calendar(tester).timeSlotViewSettings.startHour;
    final minutes = hour * 60 + minute - start * 60;
    await tester.tapAt(Offset(
        rect.left + AppointmentCalendar.timeRulerSize + 150,
        rect.top + minutes / 30 * 70 + 35));
    await tester.pumpAndSettle();
  }

  group('rango y zonas no reservables', () {
    testWidgets('abre de 9 a 20: la vista de día va de 9 a 20', (tester) async {
      await pumpAgenda(tester);
      final settings = calendar(tester).timeSlotViewSettings;
      expect((settings.startHour, settings.endHour), (9.0, 20.0));
      expect(calendar(tester).specialRegions, isEmpty);
      expect(find.byKey(AgendaDayNotice.closedKey), findsNothing);
    });

    testWidgets('franja partida: el mediodía sombreado con "Cerrado"',
        (tester) async {
      settings.opening = splitMonday();
      await pumpAgenda(tester);
      final c = calendar(tester);
      expect((c.timeSlotViewSettings.startHour, c.timeSlotViewSettings.endHour),
          (9.0, 19.0));
      final regions = c.specialRegions!;
      expect(regions, hasLength(1));
      expect(regions.single.startTime, DateTime(2030, 1, 7, 13));
      expect(regions.single.endTime, DateTime(2030, 1, 7, 15));
      expect(find.text(AppointmentCalendar.closedRegionText), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin horario de apertura: el del equipo', (tester) async {
      settings.opening = null;
      await pumpAgenda(tester);
      final s = calendar(tester).timeSlotViewSettings;
      expect((s.startHour, s.endHour), (9.0, 20.0));
    });

    testWidgets('semana: unión de los días abiertos y domingo sombreado',
        (tester) async {
      settings.opening = OpeningHours(const [
        OpeningHoursRange(
            dayOfWeek: 1, hours: WorkHours(start: '09:00', end: '13:00')),
        OpeningHoursRange(
            dayOfWeek: 6, hours: WorkHours(start: '08:00', end: '12:00')),
      ]);
      final c = await pumpAgenda(tester);
      await c.changeView(CalendarView.week);
      await tester.pumpAndSettle();
      final s = calendar(tester).timeSlotViewSettings;
      expect((s.startHour, s.endHour), (8.0, 13.0));
      final regions = calendar(tester).specialRegions!;
      expect(
          regions.any((r) =>
              r.startTime == DateTime(2030, 1, 13, 8) &&
              r.endTime == DateTime(2030, 1, 13, 13)),
          isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mes: los días cerrados se ven atenuados', (tester) async {
      final c = await pumpAgenda(tester);
      await c.changeView(CalendarView.month);
      await tester.pumpAndSettle();
      expect(
          find.byKey(const ValueKey('month-closed-2030-1-13')), findsOneWidget);
      expect(find.byKey(const ValueKey('month-closed-2030-1-7')), findsNothing);
    });

    testWidgets('el horario cambia en "Mi negocio": la agenda se ajusta',
        (tester) async {
      final c = await pumpAgenda(tester);
      settings.opening = splitMonday();
      await c.loadHours();
      await tester.pumpAndSettle();
      expect(calendar(tester).timeSlotViewSettings.endHour, 19.0);
      expect(calendar(tester).specialRegions, hasLength(1));
    });
  });

  group('día cerrado', () {
    testWidgets('aviso claro y tocar no abre el formulario', (tester) async {
      await pumpAgenda(tester, day: sunday);
      expect(find.byKey(AgendaDayNotice.closedKey), findsOneWidget);
      expect(find.text('Los domingos el negocio está cerrado'), findsOneWidget);
      expect(find.textContaining('Abre mañana a las ${formatClock(9, 0)}'),
          findsNothing);
      expect(find.textContaining('Abre el lunes a las ${formatClock(9, 0)}'),
          findsOneWidget);

      await tapCell(tester, 10, 0);
      expect(find.text('Nueva cita'), findsNothing);
      expect(find.byKey(AgendaSlotSheet.messageKey), findsOneWidget);
      expect(find.text('Día cerrado'), findsOneWidget);
      expect(appts.slotQueries, isEmpty);
    });

    testWidgets('si aun así hay citas ese día, se muestran', (tester) async {
      appts.agenda = [
        AppointmentEntity(
          id: 'x',
          client: const AppointmentClient(
              id: 'c1', name: 'Carla', lastname: 'Díaz'),
          professionalId: 'e1',
          services: const [
            AppointmentServiceLine(
                serviceId: 's1', name: 'Corte', durationMinutes: 60, price: 1),
          ],
          startTime: DateTime(2030, 1, 13, 21),
          endTime: DateTime(2030, 1, 13, 22),
          totalPrice: 1,
        ),
      ];
      await pumpAgenda(tester, day: sunday);
      expect(find.textContaining('Las citas de este día se muestran igual'),
          findsOneWidget);
      // El rango se amplió hasta la cita (nunca se esconde).
      expect(calendar(tester).timeSlotViewSettings.endHour, 22.0);
    });
  });

  group('tocar una hora', () {
    testWidgets('fuera de horario: explica y no abre el formulario',
        (tester) async {
      settings.opening = splitMonday();
      await pumpAgenda(tester);
      await tapCell(tester, 14, 0);
      expect(find.text('Nueva cita'), findsNothing);
      expect(find.text('Fuera del horario'), findsOneWidget);
      final message =
          tester.widget<Text>(find.byKey(AgendaSlotSheet.messageKey)).data!;
      expect(
          message,
          startsWith('A las ${formatClock(14, 0)} el negocio '
              'está cerrado.'));
      expect(
          message,
          contains('de ${formatClock(15, 0)} a '
              '${formatClock(19, 0)}'));
      expect(appts.slotQueries, isEmpty);

      // "Ver horas libres" abre "Nueva cita" sin hora elegida.
      await tester.tap(find.byKey(AgendaSlotSheet.freeHoursKey));
      await tester.pumpAndSettle();
      expect(find.text('Nueva cita'), findsOneWidget);
    });

    testWidgets('dentro: abre el formulario con una profesional libre',
        (tester) async {
      // Ana está ocupada a las 12:00; Bea, libre.
      appts.free = {
        'e1': [DateTime(2030, 1, 7, 11), DateTime(2030, 1, 7, 13)],
        'e3': [DateTime(2030, 1, 7, 12), DateTime(2030, 1, 7, 12, 30)],
      };
      await pumpAgenda(tester);
      await tapCell(tester, 12, 0);
      expect(find.text('Nueva cita'), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const Key('appointment-professional')),
              matching: find.text('Bea Soto')),
          findsOneWidget);
      // Se preguntó con el servicio más corto de cada una.
      final finderQueries =
          appts.slotQueries.where((q) => q.day == monday).toList();
      expect(finderQueries.map((q) => q.serviceIds), everyElement(['s1']));
    });

    testWidgets('nadie libre: lo dice y sugiere las horas más cercanas',
        (tester) async {
      appts.free = {
        'e1': [DateTime(2030, 1, 7, 9), DateTime(2030, 1, 7, 15)],
        'e3': [DateTime(2030, 1, 7, 13, 30)],
      };
      await pumpAgenda(tester);
      await tapCell(tester, 12, 0);
      expect(find.text('Nueva cita'), findsNothing);
      expect(find.text('Sin profesionales libres'), findsOneWidget);
      expect(
          find.text('A las ${formatClock(12, 0)} no hay profesionales '
              'libres.'),
          findsOneWidget);
      final nearest = DateTime(2030, 1, 7, 13, 30);
      expect(
          find.byKey(AgendaSlotSheet.suggestionKey(nearest)), findsOneWidget);

      // Elegir una sugerencia abre el formulario con esa profesional.
      await tester.tap(find.byKey(AgendaSlotSheet.suggestionKey(nearest)));
      await tester.pumpAndSettle();
      expect(find.text('Nueva cita'), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const Key('appointment-professional')),
              matching: find.text('Bea Soto')),
          findsOneWidget);
    });

    testWidgets('la empleada: solo cuenta ella y sus horas', (tester) async {
      signInAs('Employee', userId: 'e3', name: 'Bea Soto');
      appts.free = {
        'e1': [DateTime(2030, 1, 7, 10)],
        'e3': [DateTime(2030, 1, 7, 13)],
      };
      final c = await pumpAgenda(tester);
      // Bea trabaja de 12 a 16: lo demás va sombreado.
      expect(c.dayHours(monday).closed.length, 2);
      await tapCell(tester, 10, 0);
      expect(find.text('Fuera del horario'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(AgendaSlotSheet.messageKey)).data,
          startsWith('A las ${formatClock(10, 0)} no trabajas.'));
      await tester.tap(find.byKey(AgendaSlotSheet.dismissKey));
      await tester.pumpAndSettle();

      await tapCell(tester, 12, 0);
      expect(find.text('Sin profesionales libres'), findsOneWidget);
      expect(appts.slotQueries.map((q) => q.professionalId).toSet(), {'e3'});
    });
  });

  group('filtro por profesional', () {
    testWidgets('sombrea las horas en que ella no trabaja', (tester) async {
      signInAs('Owner');
      final c = await pumpAgenda(tester);
      expect(calendar(tester).specialRegions, isEmpty);

      await tester.pumpWidget(GetMaterialApp(
        theme: ThemeConfig.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(children: [
              TextButton(
                onPressed: () => ViewSelectorBottomSheet.show(context, c),
                child: const Text('opciones'),
              ),
              const Expanded(child: AppointmentCalendar()),
            ]),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('opciones'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('agenda-filter-e3')));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(ViewSelectorBottomSheet))).pop();
      await tester.pumpAndSettle();

      expect(find.byKey(AgendaDayNotice.filterKey), findsOneWidget);
      final regions = calendar(tester).specialRegions!;
      expect(regions.map((r) => (r.startTime.hour, r.endTime.hour)),
          [(9, 12), (16, 20)]);
      await tester.tap(find.byTooltip('Ver todo el equipo'));
      await tester.pumpAndSettle();
      expect(calendar(tester).specialRegions, isEmpty);
    });
  });
}
