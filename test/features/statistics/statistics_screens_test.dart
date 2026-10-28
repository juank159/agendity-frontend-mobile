import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/features/statistics/domain/entities/client_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/employee_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_comparison_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_method_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/professional_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/service_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/entities/top_client_entity.dart';
import 'package:login_signup/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_employee_stats_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_comparison_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_method_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_professional_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_service_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_top_clients_usecase.dart';
import 'package:login_signup/features/statistics/presentation/bindings/statistics_binding.dart';
import 'package:login_signup/features/statistics/presentation/controllers/statistics_controller.dart';
import 'package:login_signup/features/statistics/presentation/screens/employee_stats_screen.dart';
import 'package:login_signup/features/statistics/presentation/screens/statistics_dashboard_screen.dart';
import 'package:login_signup/features/statistics/presentation/widgets/date_range_selector.dart';
import 'package:login_signup/shared/controller/session_controller.dart';

import '../../core/session/memory_token_store.dart';

/// Repositorio falso: pantallas, controllers y use cases son los reales.
/// Cuenta las llamadas por endpoint para comprobar qué pide cada rol.
class FakeStatisticsRepository implements StatisticsRepository {
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
  ]);
  Either<Failure, List<TopClientEntity>> topClientsResult = const Right([
    TopClientEntity(
        clientId: 'c1',
        clientName: 'Ana Pérez',
        visitCount: 2,
        totalSpent: 90000),
  ]);
  Either<Failure, EmployeeStatsEntity> employeeResult = Right(employeeStats);

  final calls = <String, int>{};
  final ranges = <StatsRange>[];
  final employeeProfessionalIds = <String?>[];
  final topClientLimits = <int>[];

  int callsTo(String name) => calls[name] ?? 0;
  int get businessCalls => calls.entries
      .where((e) => e.key != 'employee')
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
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<ClientStatsEntity>>> getPaymentStatsByClient(
      StatsRange range,
      {required int limit}) async {
    _count('byClient', range);
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<TopClientEntity>>> getTopClients(StatsRange range,
      {required int limit}) async {
    _count('topClients', range);
    topClientLimits.add(limit);
    return topClientsResult;
  }

  @override
  Future<Either<Failure, EmployeeStatsEntity>> getEmployeeStats(
      StatsRange range,
      {String? professionalId}) async {
    _count('employee', range);
    employeeProfessionalIds.add(professionalId);
    return employeeResult;
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

final employeeStats = EmployeeStatsEntity(
  summary: const EmployeeStatsSummary(
      totalAmount: 80000,
      paymentCount: 2,
      appointmentCount: 2,
      averagePerPayment: 40000),
  byService: const [
    EmployeeServiceStats(
        serviceId: 's1', serviceName: 'Manicure', count: 2, total: 50000),
  ],
  dailyEvolution: [
    EmployeeDailyStats(day: DateTime(2026, 10, 27), total: 80000, count: 2),
  ],
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

  void registerUseCases() {
    Get.put(GetPaymentStatsUseCase(repo));
    Get.put(GetPaymentComparisonUseCase(repo));
    Get.put(GetPaymentStatsByMethodUseCase(repo));
    Get.put(GetPaymentStatsByProfessionalUseCase(repo));
    Get.put(GetPaymentStatsByServiceUseCase(repo));
    Get.put(GetTopClientsUseCase(repo));
    Get.put(GetEmployeeStatsUseCase(repo));
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

      await tapText(tester, 'Mejores clientes');
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('2 citas pagadas'), findsOneWidget);
      expect(repo.topClientLimits, [StatisticsController.topClientsLimit]);

      // El panel del Owner nunca pide employee-stats (sin professionalId da 400).
      expect(repo.callsTo('employee'), 0);
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
      expect(find.text('\$ 20.000'), findsWidgets);
    });

    testWidgets('un Employee en el panel no hace peticiones (sin 403)',
        (tester) async {
      signInAs('Employee');
      putDashboardController();
      await pump(tester, const StatisticsDashboardScreen());

      expect(find.text('Sin acceso'), findsOneWidget);
      expect(repo.businessCalls, 0);
      expect(repo.callsTo('employee'), 0);
    });
  });

  group('Mis estadísticas', () {
    testWidgets(
        'el Employee solo pide las suyas: sin resumen del negocio ni 403',
        (tester) async {
      signInAs('Employee');
      registerUseCases();
      EmployeeStatsBinding().dependencies();
      await pump(tester, const EmployeeStatsScreen());

      expect(repo.callsTo('employee'), 1);
      expect(repo.employeeProfessionalIds, [null]);
      expect(repo.businessCalls, 0);
      expect(find.text('Sin acceso'), findsNothing);

      expect(find.text('\$ 80.000'), findsWidgets);
      expect(find.text('Manicure'), findsOneWidget);
      // `daily_evolution.count` cuenta pagos (no citas).
      expect(find.text('2 pagos'), findsOneWidget);
    });

    testWidgets('el Owner ve las de su propio usuario (con professionalId)',
        (tester) async {
      signInAs('Owner', userId: 'owner-1');
      registerUseCases();
      EmployeeStatsBinding().dependencies();
      await pump(tester, const EmployeeStatsScreen());

      expect(repo.employeeProfessionalIds, ['owner-1']);
      expect(repo.businessCalls, 0);
    });

    testWidgets('sin pagos en el período muestra el estado vacío',
        (tester) async {
      signInAs('Employee');
      repo.employeeResult = const Right(EmployeeStatsEntity());
      registerUseCases();
      EmployeeStatsBinding().dependencies();
      await pump(tester, const EmployeeStatsScreen());

      expect(find.text('Sin pagos en este período'), findsOneWidget);
    });

    testWidgets('un error se muestra con reintento', (tester) async {
      signInAs('Employee');
      repo.employeeResult = const Left(ServerFailure());
      registerUseCases();
      EmployeeStatsBinding().dependencies();
      await pump(tester, const EmployeeStatsScreen());

      expect(find.text(ServerFailure.defaultMessage), findsOneWidget);

      repo.employeeResult = Right(employeeStats);
      await tapText(tester, 'Reintentar');

      expect(repo.callsTo('employee'), 2);
      expect(find.text('Manicure'), findsOneWidget);
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
}
