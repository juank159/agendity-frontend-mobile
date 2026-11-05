import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/appointment_payment_status_enum.dart';
import 'package:login_signup/common/enums/appointment_status_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/features/statistics/domain/entities/commission_settlement.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_comparison_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_method_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/professional_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/service_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/entities/top_client_entity.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_commission_settlement_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_comparison_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_method_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_professional_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_service_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_top_clients_usecase.dart';
import 'package:login_signup/features/statistics/presentation/controllers/commissions_controller.dart';
import 'package:login_signup/features/statistics/presentation/controllers/statistics_controller.dart';
import 'package:login_signup/features/statistics/presentation/screens/commissions_screen.dart';
import 'package:login_signup/features/statistics/presentation/screens/my_earnings_screen.dart';
import 'package:login_signup/features/statistics/presentation/screens/statistics_dashboard_screen.dart';
import 'package:login_signup/features/statistics/presentation/widgets/date_range_selector.dart';
import 'package:login_signup/features/statistics/presentation/widgets/my_earnings_view.dart';
import 'package:login_signup/features/statistics/presentation/widgets/payment_comparison_card.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';

import '../../core/session/memory_token_store.dart';

/// Repositorio falso: pantallas, controllers y use cases son los reales.
/// Cuenta las llamadas por endpoint para comprobar qué pide cada rol.
class FakeStatisticsRepository implements StatisticsRepository {
  Either<Failure, CommissionSettlement> commissionResult =
      const Right(CommissionSettlement(totals: CommissionAmounts()));
  final commissionRequests = <String?>[];

  Either<Failure, PaymentStatsEntity> statsResult = const Right(
      PaymentStatsEntity(
          totalAmount: 150000, paymentCount: 3, averageAmount: 50000));
  Either<Failure, PaymentComparisonEntity> comparisonResult = Right(comparison);
  Either<Failure, List<PaymentMethodStatsEntity>> byMethodResult = const Right([
    PaymentMethodStatsEntity(
        method: 'CASH',
        paymentMethod: PaymentMethod.CASH,
        count: 2,
        total: 100000,
        average: 50000,
        percentage: 66.67),
    PaymentMethodStatsEntity(
        method: 'Nequi',
        methodType: PaymentMethodType.custom,
        customPaymentMethodId: 'cpm-1',
        count: 1,
        total: 50000,
        average: 50000,
        percentage: 33.33),
  ]);
  Either<Failure, List<ServiceStatsEntity>> byServiceResult = const Right([
    ServiceStatsEntity(
        serviceId: 's1',
        serviceName: 'Cejas en hilo',
        appointmentCount: 3,
        paymentCount: 4,
        totalAmount: 150000,
        averageAmount: 50000,
        percentageOfTotal: 100),
  ]);
  Either<Failure, List<TopClientEntity>> topClientsResult = const Right([
    TopClientEntity(
        clientId: 'c1',
        clientName: 'Ana Pérez',
        visitCount: 2,
        totalSpent: 90000),
  ]);

  final calls = <String, int>{};
  final ranges = <StatsRange>[];
  final topClientLimits = <int>[];

  int callsTo(String name) => calls[name] ?? 0;
  int get businessCalls => calls.entries
      .where((e) => e.key != 'commissions')
      .fold(0, (sum, e) => sum + e.value);

  void _count(String name, StatsRange range) {
    calls[name] = callsTo(name) + 1;
    ranges.add(range);
  }

  @override
  Future<Either<Failure, PaymentStatsEntity>> getPaymentStats(
      StatsRange range) async {
    _count('stats', range);
    return statsResult;
  }

  @override
  Future<Either<Failure, PaymentComparisonEntity>> getPaymentComparison(
      StatsRange range) async {
    _count('comparison', range);
    return comparisonResult;
  }

  @override
  Future<Either<Failure, List<PaymentMethodStatsEntity>>>
      getPaymentStatsByMethod(StatsRange range) async {
    _count('byMethod', range);
    return byMethodResult;
  }

  @override
  Future<Either<Failure, List<ProfessionalStatsEntity>>>
      getPaymentStatsByProfessional(StatsRange range) async {
    _count('byProfessional', range);
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<ServiceStatsEntity>>> getPaymentStatsByService(
      StatsRange range) async {
    _count('byService', range);
    return byServiceResult;
  }

  @override
  Future<Either<Failure, List<TopClientEntity>>> getTopClients(StatsRange range,
      {required int limit}) async {
    _count('topClients', range);
    topClientLimits.add(limit);
    return topClientsResult;
  }

  // Liquidación de comisiones (8.03) y "Mis ganancias" (D-27).
  @override
  Future<Either<Failure, CommissionSettlement>> getCommissionSettlement(
      StatsRange range,
      {String? professionalId}) async {
    _count('commissions', range);
    commissionRequests.add(professionalId);
    return commissionResult;
  }
}

final comparison = PaymentComparisonEntity(
  currentPeriod: PeriodStatsEntity(
      startDate: DateTime(2026, 10, 27),
      endDate: DateTime(2026, 10, 27),
      totalAmount: 150000,
      paymentCount: 3,
      averageAmount: 50000),
  previousPeriod: PeriodStatsEntity(
      startDate: DateTime(2026, 10, 26),
      endDate: DateTime(2026, 10, 26),
      totalAmount: 100000,
      paymentCount: 2,
      averageAmount: 50000),
  change: const ChangeStatsEntity(
      amountDifference: 50000,
      amountPercentage: 50,
      countDifference: 1,
      countPercentage: 50,
      averageDifference: 0,
      averagePercentage: 0),
);

void main() {
  late FakeStatisticsRepository repo;
  final today = DateTime(2026, 10, 27);
  DateTime clock() => DateTime(2026, 10, 27, 10, 30);

  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    Get.testMode = true;
    repo = FakeStatisticsRepository();
  });
  tearDown(Get.reset);

  void signInAs(String role, {String userId = 'u1'}) {
    final store = MemoryTokenStore();
    final session = SessionController(SessionService(
      tokenStore: store,
      repository: SessionRepository(store),
    ));
    session.session.value =
        Session(token: 't-$role', userId: userId, roles: [role]);
    Get.put<SessionController>(session, permanent: true);
  }

  StatisticsController putDashboardController() => Get.put(StatisticsController(
        getPaymentStatsUseCase: GetPaymentStatsUseCase(repo),
        getPaymentComparisonUseCase: GetPaymentComparisonUseCase(repo),
        getPaymentStatsByMethodUseCase: GetPaymentStatsByMethodUseCase(repo),
        getPaymentStatsByProfessionalUseCase:
            GetPaymentStatsByProfessionalUseCase(repo),
        getPaymentStatsByServiceUseCase: GetPaymentStatsByServiceUseCase(repo),
        getTopClientsUseCase: GetTopClientsUseCase(repo),
        session: Get.find<SessionController>(),
        clock: clock,
      ));

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(GetMaterialApp(
      theme: ThemeConfig.lightTheme,
      home: home,
    ));
    await tester.pumpAndSettle();
  }

  /// El panel es un `ListView` perezoso: primero se desplaza hasta el texto.
  Future<void> tapText(WidgetTester tester, String text,
      {bool up = false}) async {
    await tester.scrollUntilVisible(find.text(text), up ? -200 : 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  group('Panel del negocio (Owner)', () {
    testWidgets('muestra el resumen, la comparación y los bloques al abrirlos',
        (tester) async {
      signInAs('Owner');
      putDashboardController();
      await pump(tester, const StatisticsDashboardScreen());

      expect(find.text('Ingresos netos'), findsWidgets);
      expect(find.text('\$ 150.000'), findsWidgets);
      // 12.07: el resumen (KPI) es más alto; la comparación queda debajo.
      await tester.scrollUntilVisible(find.text('Anterior: \$ 100.000'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Anterior: \$ 100.000'), findsOneWidget);
      expect(find.text('50 %'), findsWidgets);
      // Hoy por defecto, un solo día del negocio.
      expect(repo.ranges.first, StatsRange.day(today));
      // Los bloques plegables no se piden hasta abrirlos.
      expect(repo.callsTo('byMethod'), 0);

      await tapText(tester, 'Métodos de pago');
      expect(repo.callsTo('byMethod'), 1);
      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('2 pagos'), findsOneWidget);
      // Método propio (2.28): su nombre como etiqueta.
      expect(find.text('Nequi'), findsOneWidget);
      expect(find.text('1 pago'), findsOneWidget);

      await tapText(tester, 'Servicios');
      expect(find.text('Cejas en hilo'), findsOneWidget);
      // "N citas" con appointment_count, no con los pagos.
      expect(find.text('3 citas · 100 %'), findsOneWidget);

      await tapText(tester, 'Mejores clientes');
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('2 citas pagadas'), findsOneWidget);
      expect(repo.topClientLimits, [StatisticsController.topClientsLimit]);

      // El panel del Owner no pide la liquidación (es otra pantalla).
      expect(repo.callsTo('commissions'), 0);
    });

    testWidgets('cambiar de período recarga lo visible con el nuevo rango',
        (tester) async {
      signInAs('Owner');
      putDashboardController();
      await pump(tester, const StatisticsDashboardScreen());
      await tapText(tester, 'Métodos de pago');

      await tapText(tester, StatsPeriodPreset.thisMonth.label, up: true);

      final month = StatsRange(start: DateTime(2026, 10, 1), end: today);
      expect(repo.callsTo('stats'), 2);
      expect(repo.callsTo('byMethod'), 2);
      expect(repo.ranges.last, month);
      expect(find.text('Del 01/10/2026 al 27/10/2026'), findsOneWidget);
    });

    testWidgets('un período sin pagos muestra el estado vacío, no un error',
        (tester) async {
      signInAs('Owner');
      repo.statsResult = const Right(PaymentStatsEntity.empty);
      putDashboardController();
      await pump(tester, const StatisticsDashboardScreen());

      expect(find.text('Sin pagos en este período'), findsOneWidget);
      expect(find.text('No se pudo cargar'), findsNothing);
    });

    testWidgets('un error se muestra con reintento y reintentar carga',
        (tester) async {
      signInAs('Owner');
      repo.statsResult =
          const Left(NetworkFailure(message: 'Sin conexión a internet'));
      putDashboardController();
      await pump(tester, const StatisticsDashboardScreen());

      expect(find.text('No se pudo cargar'), findsOneWidget);
      expect(find.text('Sin conexión a internet'), findsOneWidget);

      repo.statsResult = const Right(PaymentStatsEntity(
          totalAmount: 20000, paymentCount: 1, averageAmount: 20000));
      await tapText(tester, 'Reintentar');

      expect(find.text('No se pudo cargar'), findsNothing);
      // 12.03: el estado de error es más alto; el resumen quedó arriba.
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('\$ 20.000'), findsWidgets);
    });

    testWidgets('un Employee en el panel no hace peticiones (sin 403)',
        (tester) async {
      signInAs('Employee');
      putDashboardController();
      await pump(tester, const StatisticsDashboardScreen());

      expect(find.text('Sin acceso'), findsOneWidget);
      expect(repo.businessCalls, 0);
      expect(repo.callsTo('commissions'), 0);
    });
  });

  group('StatsPeriodPreset', () {
    test('rangos que terminan hoy y se reconocen', () {
      final tuesday = DateTime(2026, 10, 27);
      expect(StatsPeriodPreset.thisWeek.rangeFor(tuesday),
          StatsRange(start: DateTime(2026, 10, 26), end: tuesday));
      expect(StatsPeriodPreset.last30Days.rangeFor(tuesday),
          StatsRange(start: DateTime(2026, 9, 28), end: tuesday));
      expect(StatsPeriodPreset.matching(StatsRange.day(tuesday), tuesday),
          StatsPeriodPreset.today);
      expect(
          StatsPeriodPreset.matching(
              StatsRange(start: DateTime(2026, 1, 1), end: tuesday), tuesday),
          isNull);
    });
  });

  group('Comisiones (8.03)', () {
    final settlement = CommissionSettlement(
      totals: const CommissionAmounts(
          servicesTotal: 150000,
          professionalTotal: 52500,
          businessTotal: 97500),
      appointmentCount: 2,
      professionals: [
        ProfessionalCommission(
          professionalId: 'e1',
          professionalName: 'Ana Pérez',
          appointmentCount: 2,
          amounts: const CommissionAmounts(
              servicesTotal: 150000,
              professionalTotal: 52500,
              businessTotal: 97500),
          appointments: [
            CommissionAppointment(
              appointmentId: 'a1',
              date: DateTime(2026, 10, 27, 9),
              clientName: 'Carla Díaz',
              amounts: const CommissionAmounts(
                  servicesTotal: 100000,
                  professionalTotal: 40000,
                  businessTotal: 60000),
              lines: const [
                CommissionLine(
                    serviceId: 's1',
                    serviceName: 'Laminado de cejas',
                    price: 100000,
                    commissionPercentage: 40,
                    commission: 40000),
              ],
            ),
          ],
        ),
      ],
    );

    Future<CommissionsController> pumpCommissions(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = Get.put(CommissionsController(
        getCommissionSettlementUseCase: GetCommissionSettlementUseCase(repo),
        clock: clock,
      ));
      await pump(tester, const CommissionsScreen());
      return controller;
    }

    testWidgets('Owner: totales, una fila por profesional y detalle por cita',
        (tester) async {
      signInAs('Owner');
      repo.commissionResult = Right(settlement);
      await pumpCommissions(tester);

      expect(find.text('Comisiones'), findsOneWidget);
      expect(repo.commissionRequests, [null]);
      expect(find.textContaining('2 citas completadas'), findsOneWidget);
      expect(find.text('\$ 97.500'), findsNWidgets(2));
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.textContaining('Carla Díaz'), findsNothing);

      await tester.tap(find.text('Ana Pérez'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Carla Díaz'), findsOneWidget);
      expect(find.textContaining('Laminado de cejas: \$ 100.000 × 40 %'),
          findsOneWidget);
    });


    group('Mis ganancias (D-27)', () {
      // Lo que manda el servidor a la empleada: sin `business_total`.
      CommissionAppointment visit(String id, DateTime date, String client,
              double price, double cut,
              {AppointmentStatus? status,
              AppointmentPaymentStatus? payment,
              double? paid}) =>
          CommissionAppointment(
            appointmentId: id,
            date: date,
            clientName: client,
            amounts: CommissionAmounts(
                servicesTotal: price,
                professionalTotal: cut,
                businessTotal: null),
            lines: [
              CommissionLine(
                  serviceId: 's1',
                  serviceName: 'Laminado de cejas',
                  price: price,
                  commissionPercentage: 40,
                  commission: cut),
            ],
            status: status,
            paymentStatus: payment,
            paidAmount: paid,
          );
      CommissionSettlement own(List<CommissionAppointment> list) =>
          CommissionSettlement(
            totals: CommissionAmounts(
                servicesTotal: list.fold(0, (s, a) => s + a.amounts.servicesTotal),
                professionalTotal:
                    list.fold(0, (s, a) => s + a.amounts.professionalTotal),
                businessTotal: null),
            appointmentCount: list.length,
            professionals: [
              if (list.isNotEmpty)
                ProfessionalCommission(
                  professionalId: 'e1',
                  professionalName: 'Ana Pérez',
                  appointmentCount: list.length,
                  amounts: const CommissionAmounts(businessTotal: null),
                  appointments: list,
                ),
            ],
          );
      final earnings = CommissionSettlement(
        totals: own([
          visit('a1', DateTime(2026, 10, 27, 9), 'Carla Díaz', 100000, 40000),
        ]).totals,
        appointmentCount: 1,
        professionals: own([
          visit('a1', DateTime(2026, 10, 27, 9), 'Carla Díaz', 100000, 40000),
        ]).professionals,
        pending: own([
          visit('a2', DateTime(2026, 10, 27, 15), 'Rosa Gil', 50000, 20000,
              status: AppointmentStatus.CONFIRMED,
              payment: AppointmentPaymentStatus.COMPLETED,
              paid: 50000),
          visit('a3', DateTime(2026, 10, 27, 17), 'Lina Mora', 25000, 10000,
              status: AppointmentStatus.PENDING,
              payment: AppointmentPaymentStatus.PENDING,
              paid: 0),
        ]),
      );

      Future<void> pumpEarnings(WidgetTester tester,
          {ThemeData? theme, double width = 390}) async {
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        Get.put(CommissionsController(
          getCommissionSettlementUseCase: GetCommissionSettlementUseCase(repo),
          clock: clock,
        ));
        await tester.pumpWidget(GetMaterialApp(
          theme: theme ?? ThemeConfig.lightTheme,
          home: const MyEarningsScreen(),
        ));
        await tester.pumpAndSettle();
      }

      testWidgets(
          'Ganado, Por ganar con su nota y el detalle por cita, sin "Negocio" '
          '(390 px)', (tester) async {
        signInAs('Employee', userId: 'e1');
        repo.commissionResult = Right(earnings);
        await pumpEarnings(tester);

        expect(find.text('Mis ganancias'), findsOneWidget);
        expect(repo.commissionRequests, [null]);
        expect(
            find.descendant(
                of: find.byKey(const Key('earnings-earned')),
                matching: find.text('\$ 40.000')),
            findsOneWidget);
        expect(find.text('1 cita completada'), findsOneWidget);
        expect(
            find.descendant(
                of: find.byKey(const Key('earnings-pending')),
                matching: find.text('\$ 30.000')),
            findsOneWidget);
        expect(find.text('2 citas sin completar'), findsOneWidget);
        expect(find.text(MyEarningsView.pendingNote), findsOneWidget);
        // Detalle: cliente, servicio con precio × % = comisión.
        expect(find.textContaining('Carla Díaz'), findsOneWidget);
        expect(
            find.text('Laminado de cejas: \$ 100.000 × 40 % = \$ 40.000'),
            findsOneWidget);
        // Por ganar: estado de la cita y si está pagada.
        expect(find.textContaining('Rosa Gil'), findsOneWidget);
        expect(find.text('Confirmada'), findsOneWidget);
        expect(find.text('Pagada'), findsOneWidget);
        expect(find.text('Pendiente'), findsOneWidget);
        expect(find.text('Sin pagar'), findsOneWidget);
        expect(find.text('Tu comisión'), findsNWidgets(3));
        // Nunca lo del negocio.
        expect(find.text('Negocio'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('aunque el servidor enviara lo del negocio, no se muestra',
          (tester) async {
        signInAs('Employee', userId: 'e1');
        repo.commissionResult = Right(settlement);
        await pumpEarnings(tester);
        expect(find.textContaining('Carla Díaz'), findsOneWidget);
        expect(find.text('Negocio'), findsNothing);
        expect(find.text('\$ 60.000'), findsNothing);
        expect(find.text('\$ 97.500'), findsNothing);
      });

      testWidgets('en oscuro y sin citas: estado vacío', (tester) async {
        signInAs('Employee', userId: 'e1');
        repo.commissionResult =
            Right(CommissionSettlement(
                totals: const CommissionAmounts(),
                pending: own(const [])));
        await pumpEarnings(tester, theme: ThemeConfig.darkTheme);
        expect(find.text('Sin citas en este período'), findsOneWidget);
      });

      testWidgets('un error se muestra con reintento', (tester) async {
        signInAs('Employee', userId: 'e1');
        repo.commissionResult = const Left(ServerFailure());
        await pumpEarnings(tester);
        expect(find.text(ServerFailure.defaultMessage), findsOneWidget);

        repo.commissionResult = Right(earnings);
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('earnings-earned')), findsOneWidget);
      });
    });

    testWidgets('sin citas completadas: estado vacío', (tester) async {
      signInAs('Owner');
      await pumpCommissions(tester);
      expect(
          find.text('Sin citas completadas en este período'), findsOneWidget);
    });
  });

  testWidgets('comparación sin base: "nuevo" o "—", nunca 0 %', (tester) async {
    await pump(
        tester,
        Scaffold(
          body: PaymentComparisonCard(
            comparison: PaymentComparisonEntity(
              currentPeriod: comparison.currentPeriod,
              previousPeriod: comparison.previousPeriod,
              change: const ChangeStatsEntity(
                  amountDifference: 150000,
                  amountPercentage: null,
                  countDifference: 0,
                  countPercentage: null,
                  averageDifference: 0,
                  averagePercentage: 0),
            ),
          ),
        ));
    expect(find.text('nuevo'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('0 %'), findsOneWidget); // promedio con base: 0 %
  });
}
