import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';
import 'package:login_signup/core/config/color_contrast.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import '../../core/session/memory_token_store.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/presentation/controllers/agenda_summary_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_summary_header.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_calendar_data_source.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_tile.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';
import 'package:login_signup/features/payments/domain/usecases/get_appointment_balance_usecase.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_limits_usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/widgets/status_chip.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Agenda rediseñada (12.04): tarjeta "3D" (una por cita), cabecera de
/// resumen y navegación de la barra.
class _Repo implements AppointmentsRepository {
  List<AppointmentEntity> result = const [];
  final ranges = <AppointmentsRange>[];

  @override
  Future<Either<Failure, List<AppointmentEntity>>> getAppointments(
      AppointmentsRange range) async {
    ranges.add(range);
    return Right(result);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Payments implements PaymentRepository {
  final paid = <String, double>{};

  @override
  Future<Either<Failure, List<PaymentEntity>>> getAppointmentPayments(
          String appointmentId) async =>
      Right([
        if (paid[appointmentId] case final amount?)
          PaymentEntity(
            id: 'p-$appointmentId',
            appointmentId: appointmentId,
            amount: amount,
            paymentMethod: PaymentMethod.CASH,
            status: PaymentStatus.COMPLETED,
          ),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Informes: "ingresos" del rango = pagos con fecha en el rango, netos.
class _Stats implements StatisticsRepository {
  Either<Failure, PaymentStatsEntity> result = const Right(PaymentStatsEntity(
      totalAmount: 25000, paymentCount: 2, averageAmount: 12500));
  final ranges = <StatsRange>[];

  @override
  Future<Either<Failure, PaymentStatsEntity>> getPaymentStats(
      StatsRange range) async {
    ranges.add(range);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SubscriptionRepo implements SubscriptionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final today = DateTime(2030, 1, 7);

AppointmentEntity appointment(
  String id, {
  List<(String, String?, int)> services = const [('Corte', '#7c5cfc', 60)],
  AppointmentStatus status = AppointmentStatus.PENDING,
  AppointmentPaymentStatus payment = AppointmentPaymentStatus.PENDING,
  double total = 30000,
  DateTime? start,
  bool needsReschedule = false,
  String? professional = 'Ana Pérez',
}) {
  final begin = start ?? DateTime(2030, 1, 7, 10);
  final minutes = services.fold<int>(0, (sum, s) => sum + s.$3);
  return AppointmentEntity(
    id: id,
    client: const AppointmentClient(id: 'c1', name: 'Carla', lastname: 'Díaz'),
    professionalId: 'e1',
    professionalName: professional,
    services: [
      for (final (name, color, duration) in services)
        AppointmentServiceLine(
            serviceId: name,
            name: name,
            color: color,
            durationMinutes: duration,
            price: total / services.length),
    ],
    startTime: begin,
    endTime: begin.add(Duration(minutes: minutes)),
    status: status,
    paymentStatus: payment,
    totalPrice: total,
    needsReschedule: needsReschedule,
  );
}

const threeServices = [
  ('Corte', '#7c5cfc', 30),
  ('Tinte', '#ec4899', 60),
  ('Peinado', '#0ea5a4', 30),
];

void signInAs(String role, {String name = 'Olga Ruiz'}) {
  final store = MemoryTokenStore();
  final session = SessionController(SessionService(
    tokenStore: store,
    repository: SessionRepository(store),
  ));
  session.session.value =
      Session(token: 't', userId: 'u1', name: name, roles: [role]);
  Get.put<SessionController>(session, permanent: true);
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  setUp(() => Get.testMode = true);
  tearDown(() {
    Get.reset();
    BusinessTimeZone.reset();
    BusinessTimeZone.clock = DateTime.now;
  });

  Future<void> pumpTile(WidgetTester tester, AppointmentEntity a,
      {double width = 300, double height = 140, bool compact = false}) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeConfig.lightTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: AppointmentTile(appointment: a, compact: compact),
          ),
        ),
      ),
    ));
  }

  group('tarjeta de cita', () {
    test('el calendario pinta un solo bloque por cita, de inicio a fin', () {
      final a = appointment('a', services: threeServices);
      final source = AppointmentCalendarDataSource([a]);
      expect(source.appointments, hasLength(1));
      expect(source.getId(0), 'a');
      expect(source.getStartTime(0), DateTime(2030, 1, 7, 10));
      expect(source.getEndTime(0), DateTime(2030, 1, 7, 12));
      expect(source.getSubject(0), 'Carla Díaz\nCorte\nTinte\nPeinado');
    });

    testWidgets('varios servicios: una tarjeta con una píldora por servicio',
        (tester) async {
      await pumpTile(tester, appointment('a', services: threeServices));
      expect(tester.takeException(), isNull);
      expect(find.byType(AppointmentTile), findsOneWidget);
      expect(find.text('Carla Díaz'), findsOneWidget);
      for (final name in ['Corte', 'Tinte', 'Peinado']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(
          find.text(formatTimeRange(
              DateTime(2030, 1, 7, 10), DateTime(2030, 1, 7, 12))),
          findsOneWidget);
      // Alta: estado, pago (sin pagar) e iniciales de la profesional.
      expect(find.byType(StatusChip), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(
          find.byIcon(StatusChip.paymentIcon(AppointmentPaymentStatus.PENDING)),
          findsOneWidget);
      expect(find.text('AP'), findsOneWidget);
    });

    testWidgets('el ícono de pago sigue al estado del pago', (tester) async {
      for (final status in [
        AppointmentPaymentStatus.PARTIAL,
        AppointmentPaymentStatus.COMPLETED,
      ]) {
        await pumpTile(tester, appointment('a', payment: status));
        expect(find.byIcon(StatusChip.paymentIcon(status)), findsOneWidget);
      }
    });

    test('texto blanco o negro con contraste AA en todo el degradado', () {
      const ink = Color(0xFF111111);
      const white = Color(0xFFFFFFFF);
      Color lighter(Color c) => Color.lerp(c, white, 0.18)!;
      // Claros (amarillo, verde, azul brillante): texto oscuro y el color
      // del servicio sin tocar.
      for (final light in [
        const Color(0xFFFFC107),
        const Color(0xFF4CAF50),
        const Color(0xFF2196F3),
      ]) {
        final colors = AppointmentTile.colorsFor(light);
        expect(colors.foreground, ink);
        expect(colors.base, light);
        expect(contrastRatio(ink, light), greaterThanOrEqualTo(4.5));
      }
      // Oscuros o medios (índigo, lavanda, rosa, verde azulado): blanco; el
      // color se oscurece lo justo y conserva el tono.
      for (final hex in [0xFF1A237E, 0xFF7C5CFC, 0xFFE91E63, 0xFF009688]) {
        final service = Color(hex);
        final colors = AppointmentTile.colorsFor(service);
        expect(colors.foreground, white);
        expect(contrastRatio(white, colors.base), greaterThanOrEqualTo(4.5));
        expect(contrastRatio(white, lighter(colors.base)),
            greaterThanOrEqualTo(4.5));
        expect(HSLColor.fromColor(colors.base).hue,
            closeTo(HSLColor.fromColor(service).hue, 1));
        expect(
            HSLColor.fromColor(service).lightness -
                HSLColor.fromColor(colors.base).lightness,
            lessThanOrEqualTo(AppointmentTile.maxDarkening + 0.001));
      }
      // El azul oscuro ya cumplía: no cambia.
      expect(AppointmentTile.colorsFor(const Color(0xFF1A237E)).base,
          const Color(0xFF1A237E));
    });

    testWidgets('el cliente se pinta con el color de contraste',
        (tester) async {
      await pumpTile(
          tester, appointment('a', services: const [('Cejas', '#ffeb3b', 60)]));
      final client = tester.widget<Text>(find.text('Carla Díaz'));
      expect(client.style?.color,
          AppointmentTile.colorsFor(const Color(0xFFFFEB3B)).foreground);
    });

    testWidgets('cita corta: una línea compacta (hora · cliente · servicio +N)',
        (tester) async {
      await pumpTile(tester, appointment('a', services: threeServices),
          height: 30);
      expect(tester.takeException(), isNull);
      expect(find.text(formatTime(DateTime(2030, 1, 7, 10))), findsOneWidget);
      expect(find.text('Carla Díaz'), findsOneWidget);
      expect(find.text('Corte +2'), findsOneWidget);
      expect(find.byType(StatusChip), findsNothing);
    });

    testWidgets('columna estrecha: sin overflow y sin insignias',
        (tester) async {
      await pumpTile(tester, appointment('a', services: threeServices),
          width: 70, height: 30);
      expect(tester.takeException(), isNull);
      await pumpTile(tester, appointment('a', services: threeServices),
          width: 70, height: 140);
      expect(tester.takeException(), isNull);
      expect(find.text('AP'), findsNothing);
    });

    testWidgets('semana: solo el nombre del cliente', (tester) async {
      await pumpTile(tester, appointment('a'),
          width: 46, height: 70, compact: true);
      expect(tester.takeException(), isNull);
      expect(find.text('Carla'), findsOneWidget);
      expect(find.byType(StatusChip), findsNothing);
    });

    testWidgets('por mover: borde punteado, aviso y chip "Por mover"',
        (tester) async {
      await pumpTile(tester, appointment('a', needsReschedule: true));
      expect(find.bySemanticsLabel(RegExp('por mover')), findsOneWidget);
      expect(find.byIcon(Icons.report_problem_rounded), findsOneWidget);
      expect(find.text('Por mover'), findsOneWidget);
      final dashed = find.descendant(
          of: find.byType(AppointmentTile),
          matching: find.byWidgetPredicate(
              (w) => w is CustomPaint && w.foregroundPainter != null));
      expect(dashed, findsOneWidget);

      await pumpTile(tester, appointment('b'));
      expect(
          find.descendant(
              of: find.byType(AppointmentTile),
              matching: find.byWidgetPredicate(
                  (w) => w is CustomPaint && w.foregroundPainter != null)),
          findsNothing);
    });

    testWidgets('en oscuro también se pinta sin errores', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeConfig.darkTheme,
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 140,
            child: AppointmentTile(
                appointment: appointment('a', services: threeServices)),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('resumen de hoy', () {
    late _Repo repo;
    late _Payments payments;
    late _Stats stats;

    AgendaSummaryController summary({RxList<AppointmentEntity>? changes}) =>
        AgendaSummaryController(
          getAppointmentsUseCase: GetAppointmentsUseCase(repo),
          getAppointmentBalanceUseCase: GetAppointmentBalanceUseCase(payments),
          getPaymentStatsUseCase: GetPaymentStatsUseCase(stats),
          agendaChanges: changes,
          now: () => DateTime(2030, 1, 7, 8, 30),
        );

    setUp(() {
      repo = _Repo();
      payments = _Payments();
      stats = _Stats();
      repo.result = [
        appointment('pend', total: 50000),
        appointment('paid',
            total: 30000, payment: AppointmentPaymentStatus.COMPLETED),
        appointment('partial',
            total: 40000, payment: AppointmentPaymentStatus.PARTIAL),
        appointment('cancel',
            total: 99000, status: AppointmentStatus.CANCELLED),
        appointment('tomorrow', total: 77000, start: DateTime(2030, 1, 8, 10)),
      ];
      payments.paid['partial'] = 10000;
    });

    test('cuenta las citas de hoy y lo por cobrar; Owner: ingresos de hoy',
        () async {
      signInAs('Owner');
      final c = summary();
      await c.load();
      expect(repo.ranges.last, AppointmentsRange.day(today));
      expect(c.isLoaded.value, isTrue);
      // "Ingresos hoy" = pagos de hoy (Informes), no lo cobrado de las citas
      // de hoy (que serían 40.000).
      expect(stats.ranges.single, StatsRange.day(today));
      expect(
          c.summary.value,
          const AgendaSummary(
              appointments: 3, toCollect: 80000, income: 25000));
    });

    test('Employee: no pide los ingresos', () async {
      signInAs('Employee');
      final c = summary();
      await c.load();
      expect(stats.ranges, isEmpty);
      expect(c.summary.value.income, 0);
      expect(c.summary.value.appointments, 3);
    });

    test('si los ingresos fallan, conserva el último valor', () async {
      signInAs('Owner');
      final c = summary();
      await c.load();
      stats.result = const Left(NetworkFailure(message: 'sin red'));
      await c.load();
      expect(c.summary.value.income, 25000);
      expect(c.summary.value.appointments, 3);
    });

    test('se recalcula cuando cambia la lista de la agenda', () async {
      final changes = <AppointmentEntity>[].obs;
      final c = summary(changes: changes)..onInit();
      await pumpEventQueue();
      expect(c.summary.value.appointments, 3);

      repo.result = [appointment('solo')];
      changes.add(appointment('solo'));
      await pumpEventQueue();
      expect(c.summary.value,
          const AgendaSummary(appointments: 1, toCollect: 30000, income: 0));
      c.onClose();
    });

    test('saludo con el primer nombre; "Ingresos hoy" solo del Owner', () {
      signInAs('Owner');
      final c = summary();
      expect(c.greeting, 'Hola, Olga');
      expect(c.showsIncome, isTrue);
      Get.reset();
      signInAs('Employee', name: '');
      expect(summary().greeting, 'Hola');
      expect(summary().showsIncome, isFalse);
    });

    Future<void> pumpHeader(WidgetTester tester) async {
      Get.put(summary());
      await tester.pumpWidget(MaterialApp(
        theme: ThemeConfig.lightTheme,
        home: const Scaffold(body: AgendaSummaryHeader()),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('Owner: saludo, fecha y las tres tarjetas', (tester) async {
      signInAs('Owner');
      await pumpHeader(tester);
      expect(find.text('Hola, Olga'), findsOneWidget);
      expect(find.text(AgendaSummaryHeader.dateLabel(today)), findsOneWidget);
      expect(AgendaSummaryHeader.dateLabel(today), 'Lunes, 7 de enero');
      expect(find.text('Citas hoy'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Por cobrar'), findsOneWidget);
      expect(find.text(formatCop(80000)), findsOneWidget);
      expect(find.text('Ingresos hoy'), findsOneWidget);
      expect(find.text(formatCop(25000)), findsOneWidget);
    });

    testWidgets('Employee: sin "Ingresos hoy"', (tester) async {
      signInAs('Employee');
      await pumpHeader(tester);
      expect(find.text('Citas hoy'), findsOneWidget);
      expect(find.text('Por cobrar'), findsOneWidget);
      expect(find.text('Ingresos hoy'), findsNothing);
    });

    testWidgets('se pliega a una línea con el número de citas', (tester) async {
      signInAs('Owner');
      await pumpHeader(tester);
      await tester.tap(find.byKey(const Key('summary-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Citas hoy'), findsNothing);
      expect(find.text('${AgendaSummaryHeader.dateLabel(today)} · 3 citas'),
          findsOneWidget);
      await tester.tap(find.byKey(const Key('summary-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Citas hoy'), findsOneWidget);
    });

    testWidgets('sin controller no ocupa espacio', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeConfig.lightTheme,
        home: const Scaffold(body: AgendaSummaryHeader()),
      ));
      expect(find.text('Citas hoy'), findsNothing);
    });
  });

  group('barra de la agenda', () {
    AppointmentsController agenda() => AppointmentsController(
          getAppointmentsUseCase: GetAppointmentsUseCase(_Repo()),
          checkSubscriptionLimitsUseCase:
              CheckSubscriptionLimitsUseCase(_SubscriptionRepo()),
          now: () => DateTime(2030, 1, 7, 8, 30),
        );

    test('flechas: un día, una semana o un mes; "Hoy" vuelve', () async {
      final c = agenda();
      expect(c.showsToday, isTrue);
      await c.step(1);
      expect(c.selectedDate.value, DateTime(2030, 1, 8));
      expect(c.showsToday, isFalse);
      await c.changeView(CalendarView.week);
      await c.step(-1);
      expect(c.selectedDate.value, DateTime(2030, 1, 1));
      await c.changeView(CalendarView.month);
      await c.step(1);
      expect(c.selectedDate.value, DateTime(2030, 2, 1));
      expect(c.showsToday, isFalse);
      await c.goToToday();
      expect(c.showsToday, isTrue);
      expect(c.currentView.value, CalendarView.month);
    });
  });
}
