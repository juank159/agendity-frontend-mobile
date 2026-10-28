import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_checkout.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_limits.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/create_paid_subscription_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/get_all_plans_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/get_current_subscription_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/refresh_subscription_status_usecase.dart';
import 'package:login_signup/features/subscriptions/presentation/controllers/subscription_controller.dart';
import 'package:login_signup/features/subscriptions/presentation/screens/payment_success_screen.dart';
import 'package:login_signup/features/subscriptions/presentation/screens/payment_webview_screen.dart';
import 'package:login_signup/features/subscriptions/presentation/screens/subscription_plans_screen.dart';

/// Repositorio falso: pantallas, controller y use cases son los reales.
class FakeSubscriptionRepository implements SubscriptionRepository {
  /// Respuestas de `GET /status` en orden; la última se repite.
  List<Either<Failure, SubscriptionEntity>> statusResults = [const Right(trial)];
  Either<Failure, List<SubscriptionPlanEntity>> plansResult =
      const Right([monthly, annual]);
  Either<Failure, SubscriptionRefresh> refreshResult =
      const Right(SubscriptionRefresh(activated: false));
  Either<Failure, SubscriptionCheckout> subscribeResult = const Right(
      SubscriptionCheckout(
          paymentLink: 'myapp://payment-demo?reference=ref-1', isTest: true));

  int statusCalls = 0;
  int refreshCalls = 0;
  final subscribed = <String>[];

  @override
  Future<Either<Failure, SubscriptionEntity>> getStatus() async {
    statusCalls++;
    return statusResults.length > 1
        ? statusResults.removeAt(0)
        : statusResults.first;
  }

  @override
  Future<Either<Failure, List<SubscriptionPlanEntity>>> getPlans() async =>
      plansResult;

  @override
  Future<Either<Failure, SubscriptionLimits>> checkLimits() async =>
      const Right(SubscriptionLimits(canCreateAppointment: true));

  @override
  Future<Either<Failure, SubscriptionCheckout>> subscribe(String planId) async {
    subscribed.add(planId);
    return subscribeResult;
  }

  @override
  Future<Either<Failure, SubscriptionRefresh>> refreshStatus() async {
    refreshCalls++;
    return refreshResult;
  }
}

const monthly = SubscriptionPlanEntity(
  id: 'plan-1',
  name: 'Mensual',
  price: 50000,
  durationMonths: 1,
  appointmentLimit: 100,
);
const annual = SubscriptionPlanEntity(
  id: 'plan-12',
  name: 'Anual',
  price: 500000,
  durationMonths: 12,
  appointmentLimit: SubscriptionPlanEntity.unlimitedAppointments,
);

const trial = SubscriptionEntity(
  id: 's1',
  status: SubscriptionStatus.trial,
  trialAppointmentsUsed: 5,
  trialAppointmentsLimit: 20,
);

final pending = SubscriptionEntity(
  id: 's1',
  status: SubscriptionStatus.trial,
  trialAppointmentsUsed: 20,
  trialAppointmentsLimit: 20,
  pendingPayment: PendingPayment(
      id: 'pay-1',
      planId: annual.id,
      amount: 500000,
      createdAt: DateTime(2026)),
);

final activeAnnual = SubscriptionEntity(
  id: 's1',
  status: SubscriptionStatus.active,
  plan: annual,
  startDate: DateTime(2026, 10, 27),
  endDate: DateTime(2027, 10, 27),
);

void main() {
  late FakeSubscriptionRepository repo;

  setUpAll(() => initializeDateFormatting('es'));
  setUp(() {
    Get.testMode = true;
    repo = FakeSubscriptionRepository();
  });
  tearDown(Get.reset);

  SubscriptionController putController() => Get.put(SubscriptionController(
        getCurrentSubscriptionUseCase: GetCurrentSubscriptionUseCase(repo),
        getAllPlansUseCase: GetAllPlansUseCase(repo),
        createPaidSubscriptionUseCase: CreatePaidSubscriptionUseCase(repo),
        refreshSubscriptionStatusUseCase:
            RefreshSubscriptionStatusUseCase(repo),
      ));

  Future<void> pumpApp(WidgetTester tester, {Widget? home}) async {
    await tester.pumpWidget(GetMaterialApp(
      theme: ThemeConfig.lightTheme,
      home: home ?? const Scaffold(body: Text('inicio')),
      getPages: [
        GetPage(
            name: GetRoutes.paymentWebview,
            page: () => const PaymentWebViewScreen()),
        GetPage(
            name: GetRoutes.paymentSuccess,
            page: () => const PaymentSuccessScreen()),
      ],
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(find.text(text), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  /// Deja que el snackbar se cierre (si no, el test termina con timers).
  Future<void> expireSnackbar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  group('Pantalla de planes', () {
    testWidgets('trial: muestra las citas usadas de 20', (tester) async {
      putController();
      await pumpApp(tester, home: const SubscriptionPlansScreen());

      expect(find.text('Periodo de prueba'), findsOneWidget);
      expect(find.text('Usaste 5 de 20 citas de prueba.'), findsOneWidget);
      expect(find.text('Pago en verificación'), findsNothing);
    });

    testWidgets(
        'la duración sale de durationMonths y -1 es ilimitado (no del nombre)',
        (tester) async {
      repo.plansResult = const Right([
        SubscriptionPlanEntity(
            id: 'p6',
            name: 'Plan Pro',
            price: 270000,
            durationMonths: 6,
            appointmentLimit: 100),
        SubscriptionPlanEntity(
            id: 'p12',
            name: 'Mensual (nombre engañoso)',
            price: 500000,
            durationMonths: 12,
            appointmentLimit: -1),
      ]);
      putController();
      await pumpApp(tester, home: const SubscriptionPlansScreen());

      expect(find.textContaining('/ 6 meses'), findsOneWidget);
      expect(find.text('100 citas por periodo'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Citas ilimitadas'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('/ año'), findsOneWidget);
      expect(find.textContaining('/ mes'), findsNothing);
    });

    testWidgets('pago pendiente: aviso y "Verificar pago" consulta el backend',
        (tester) async {
      repo.statusResults = [Right(pending)];
      putController();
      await pumpApp(tester, home: const SubscriptionPlansScreen());

      expect(find.text('Pago en verificación'), findsOneWidget);
      expect(find.textContaining('\$ 500.000'), findsWidgets);
      expect(find.text('Tu periodo de prueba terminó'), findsOneWidget);

      await tapText(tester, 'Verificar pago');
      expect(repo.refreshCalls, 1);
      // Sigue pendiente: aviso, sin ir a la pantalla de éxito.
      expect(find.text('¡Gracias por tu compra!'), findsNothing);
      await expireSnackbar(tester);
    });

    testWidgets('activa cancelada al fin del periodo: "no se renovará"',
        (tester) async {
      repo.statusResults = [
        Right(SubscriptionEntity(
          id: 's1',
          status: SubscriptionStatus.active,
          plan: annual,
          endDate: DateTime(2027, 1, 15),
          cancelAtPeriodEnd: true,
        )),
      ];
      putController();
      await pumpApp(tester, home: const SubscriptionPlansScreen());

      expect(find.text('Anual cancelado'), findsOneWidget);
      expect(find.text('Activo hasta el 15/01/2027; no se renovará.'),
          findsOneWidget);
      await tester.scrollUntilVisible(find.text('Plan actual'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Plan actual'), findsOneWidget);
    });

    testWidgets('un error de carga se muestra con reintento', (tester) async {
      repo.statusResults = [const Left(NetworkFailure())];
      putController();
      await pumpApp(tester, home: const SubscriptionPlansScreen());

      expect(find.text('No se pudo cargar'), findsOneWidget);
      repo.statusResults = [const Right(trial)];
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Periodo de prueba'), findsOneWidget);
    });
  });

  group('Verificación del pago (webview, modo demo)', () {
    Future<void> openDemoCheckout(WidgetTester tester) async {
      putController();
      await pumpApp(tester);
      Get.toNamed(GetRoutes.paymentWebview,
          arguments: {'url': 'myapp://payment-demo?reference=ref-1'});
      // Detrás del diálogo hay un indicador de carga: no se asienta nunca.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Pago de prueba'), findsOneWidget);
      await tester.tap(find.text('Simular pago aprobado'));
      await tester.pumpAndSettle();
    }

    testWidgets('active: refresh-status y luego éxito con el plan verificado',
        (tester) async {
      repo.refreshResult = const Right(SubscriptionRefresh(activated: true));
      repo.statusResults = [const Right(trial), Right(activeAnnual)];
      await openDemoCheckout(tester);

      expect(repo.refreshCalls, 1);
      expect(find.text('¡Gracias por tu compra!'), findsOneWidget);
      expect(find.text('Anual'), findsOneWidget);
      expect(find.text('Citas ilimitadas'), findsOneWidget);
      expect(find.text('27/10/2027'), findsOneWidget);
    });

    testWidgets('pendiente: "Pago en proceso" y verificar de nuevo',
        (tester) async {
      repo.statusResults = [Right(pending)];
      await openDemoCheckout(tester);

      expect(find.text('Pago en proceso'), findsOneWidget);
      expect(find.text('¡Gracias por tu compra!'), findsNothing);

      repo.refreshResult = const Right(SubscriptionRefresh(activated: true));
      repo.statusResults = [Right(activeAnnual)];
      await tester.tap(find.text('Verificar de nuevo'));
      await tester.pumpAndSettle();

      expect(repo.refreshCalls, 2);
      expect(find.text('¡Gracias por tu compra!'), findsOneWidget);
    });

    testWidgets('error: muestra el fallo y permite volver a los planes',
        (tester) async {
      repo.refreshResult = const Left(NetworkFailure());
      await openDemoCheckout(tester);

      expect(find.text('No se pudo verificar el pago'), findsOneWidget);
      expect(find.textContaining('Revisa tu conexión'), findsOneWidget);

      await tester.tap(find.text('Volver a los planes'));
      await tester.pumpAndSettle();
      expect(find.text('inicio'), findsOneWidget);
    });

    testWidgets('sin pago confirmado ni pendiente: no da el pago por hecho',
        (tester) async {
      // Wompi lo rechazó: sin intento pendiente y sigue en trial.
      await openDemoCheckout(tester);

      expect(find.text('Pago no confirmado'), findsOneWidget);
      expect(find.text('¡Gracias por tu compra!'), findsNothing);
    });
  });

  test('isPaymentCallbackUrl', () {
    expect(isPaymentCallbackUrl('myapp://payment-callback?id=1'), isTrue);
    expect(isPaymentCallbackUrl('https://x.com/payment-callback?id=1'), isTrue);
    expect(isPaymentCallbackUrl('myapp://payment-demo?reference=r'), isFalse);
    expect(
        isPaymentCallbackUrl('https://checkout.wompi.co/l/abc?id=1'), isFalse);
  });
}
