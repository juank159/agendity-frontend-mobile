import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/payments/domain/entities/custom_payment_method.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/payments/domain/failures/payment_failures.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';
import 'package:login_signup/features/payments/domain/usecases/create_payment_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_active_custom_payment_methods_usecase.dart';
import 'package:login_signup/features/payments/presentation/controllers/payment_controller.dart';
import 'package:login_signup/features/payments/presentation/widgets/payment_dialog.dart';

/// Repositorio falso: el diálogo, el controller y el use case son reales.
class FakePaymentRepository implements PaymentRepository {
  Either<Failure, PaymentEntity>? result;
  final sent = <PaymentEntity>[];

  @override
  Future<Either<Failure, PaymentEntity>> createPayment(
      PaymentEntity payment) async {
    sent.add(payment);
    return result ?? Right(payment.copyWith(id: 'pay-1'));
  }

  Either<Failure, List<CustomPaymentMethod>> customMethods = const Right([]);

  @override
  Future<Either<Failure, List<CustomPaymentMethod>>>
      getActiveCustomPaymentMethods() async => customMethods;

  @override
  Future<Either<Failure, List<PaymentEntity>>> getAppointmentPayments(
          String appointmentId) async =>
      const Right([]);
}

final appointment = AppointmentEntity(
  id: 'apt-1',
  client: const AppointmentClient(id: 'cli-1', name: 'Ana'),
  professionalId: 'pro-1',
  services: const [
    AppointmentServiceLine(serviceId: 'svc-1', name: 'Corte', price: 45000),
  ],
  startTime: DateTime(2026, 11, 3, 10),
  endTime: DateTime(2026, 11, 3, 11),
  totalPrice: 45000,
);

void main() {
  late FakePaymentRepository repo;
  late bool? dialogResult;

  setUp(() {
    Get.testMode = true;
    repo = FakePaymentRepository();
    dialogResult = null;
    Get.put(PaymentController(
        createPaymentUseCase: CreatePaymentUseCase(repo),
        getActiveCustomPaymentMethodsUseCase:
            GetActiveCustomPaymentMethodsUseCase(repo)));
  });
  tearDown(Get.reset);

  Future<void> openDialog(WidgetTester tester,
      {List<CustomPaymentMethod> customMethods = const []}) async {
    await tester.pumpWidget(GetMaterialApp(
      theme: ThemeConfig.lightTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => dialogResult = await PaymentDialog.show(
                appointment,
                customMethods: customMethods),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> expireSnackbar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el total con formatCop y lo propone como monto',
      (tester) async {
    await openDialog(tester);
    expect(find.text('\$ 45.000'), findsOneWidget);
    final amount =
        tester.widget<TextField>(find.byKey(const Key('payment-amount')));
    expect(amount.controller!.text, '45000');
    expect(find.text('Otro método'), findsNothing);
  });

  testWidgets('monto total válido → registra, cierra y avisa', (tester) async {
    await openDialog(tester);
    await tapText(tester, 'Tarjeta de débito');
    await tapText(tester, 'Confirmar pago');

    expect(repo.sent.single.amount, 45000);
    expect(repo.sent.single.paymentMethod, PaymentMethod.DEBIT_CARD);
    expect(dialogResult, isTrue);
    expect(find.text('Registrar pago'), findsNothing);
    expect(find.text('Pago registrado: \$ 45.000'), findsOneWidget);
    await expireSnackbar(tester);
  });

  testWidgets('anticipo: pide confirmación y envía el monto parcial',
      (tester) async {
    await openDialog(tester);
    await tester.enterText(find.byKey(const Key('payment-amount')), '20.000');
    await tapText(tester, 'Confirmar pago');
    expect(find.text('¿Registrar un anticipo?'), findsOneWidget);
    await tapText(tester, 'Registrar anticipo');

    expect(repo.sent.single.amount, 20000);
    expect(dialogResult, isTrue);
    await expireSnackbar(tester);
  });

  testWidgets('mayor que el total → error en el campo, sin enviar',
      (tester) async {
    await openDialog(tester);
    await tester.enterText(find.byKey(const Key('payment-amount')), '50000');
    await tapText(tester, 'Confirmar pago');

    expect(repo.sent, isEmpty);
    expect(find.text(InvalidPaymentAmountFailure.exceedsTotalMessage),
        findsOneWidget);
    expect(find.text('Registrar pago'), findsOneWidget);
  });

  testWidgets('monto vacío o cero → error en el campo', (tester) async {
    await openDialog(tester);
    await tester.enterText(find.byKey(const Key('payment-amount')), '');
    await tapText(tester, 'Confirmar pago');
    expect(repo.sent, isEmpty);
    expect(find.text(InvalidPaymentAmountFailure.notPositiveMessage),
        findsOneWidget);
  });

  testWidgets('método propio sin elegir → error en el selector, sin enviar',
      (tester) async {
    await openDialog(tester, customMethods: const [
      CustomPaymentMethod(id: 'cm-1', name: 'Nequi'),
    ]);
    await tapText(tester, 'Otro método');
    await tapText(tester, 'Confirmar pago');

    expect(repo.sent, isEmpty);
    expect(find.text('Elige el método de pago'), findsOneWidget);

    await tester.tap(find.byKey(const Key('payment-custom-method')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nequi').last);
    await tester.pumpAndSettle();
    await tapText(tester, 'Confirmar pago');
    expect(repo.sent.single.customPaymentMethodId, 'cm-1');
    expect(repo.sent.single.paymentMethod, PaymentMethod.CUSTOM);
    await expireSnackbar(tester);
  });

  testWidgets('cita cancelada (backend) → aviso claro y el diálogo sigue',
      (tester) async {
    repo.result = const Left(AppointmentNotPayableFailure(
        message: 'Invalid transition CANCELLED -> CONFIRMED'));
    await openDialog(tester);
    await tapText(tester, 'Confirmar pago');

    expect(find.text(AppointmentNotPayableFailure.defaultMessage),
        findsOneWidget);
    expect(find.text('Registrar pago'), findsOneWidget);
    expect(dialogResult, isNull);
    await expireSnackbar(tester);
  });

  testWidgets('otro error del backend → su mensaje', (tester) async {
    repo.result = const Left(
        ValidationFailure(message: 'La cita ya tiene un pago completado'));
    await openDialog(tester);
    await tapText(tester, 'Confirmar pago');
    expect(find.text('La cita ya tiene un pago completado'), findsOneWidget);
    await expireSnackbar(tester);
  });

  test('parseAmount acepta los formatos que escribe el usuario', () {
    expect(PaymentController.parseAmount('45000'), 45000);
    expect(PaymentController.parseAmount('45.000'), 45000);
    expect(PaymentController.parseAmount('\$ 45.000'), 45000);
    expect(PaymentController.parseAmount('45000,5'), 45000.5);
    expect(PaymentController.parseAmount(''), isNull);
    expect(PaymentController.parseAmount('abc'), isNull);
  });

  group('métodos propios (GET /custom-payment-methods/active)', () {
    testWidgets('con métodos activos se ofrece "Otro método" y sus nombres',
        (tester) async {
      repo.customMethods =
          const Right([CustomPaymentMethod(id: 'cm-1', name: 'Nequi')]);
      final methods = await Get.find<PaymentController>().loadCustomMethods();
      await openDialog(tester, customMethods: methods);
      await tapText(tester, 'Otro método');
      await tester.tap(find.byKey(const Key('payment-custom-method')));
      await tester.pumpAndSettle();
      expect(find.text('Nequi'), findsWidgets);
    });

    testWidgets('lista vacía → "Otro método" oculto', (tester) async {
      final methods = await Get.find<PaymentController>().loadCustomMethods();
      expect(methods, isEmpty);
      await openDialog(tester, customMethods: methods);
      expect(find.text('Otro método'), findsNothing);
      expect(find.text('Efectivo'), findsOneWidget);
    });

    testWidgets('403 (Employee) → sin "Otro método" y sin error',
        (tester) async {
      repo.customMethods = const Left(ForbiddenFailure(statusCode: 403));
      final methods = await Get.find<PaymentController>().loadCustomMethods();
      expect(methods, isEmpty);
      await openDialog(tester, customMethods: methods);
      expect(find.text('Otro método'), findsNothing);
      expect(find.text(ForbiddenFailure.defaultMessage), findsNothing);
      expect(find.text('Confirmar pago'), findsOneWidget);
    });
  });
}
