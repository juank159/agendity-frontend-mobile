import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/payments/domain/entities/appointment_balance.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';
import 'package:login_signup/features/payments/domain/usecases/get_appointment_balance_usecase.dart';

class _Repo implements PaymentRepository {
  final List<PaymentEntity> payments;

  _Repo(this.payments);

  @override
  Future<Either<Failure, List<PaymentEntity>>> getAppointmentPayments(
          String appointmentId) async =>
      Right(payments);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PaymentEntity _payment(String id, double amount,
        {DateTime? at,
        PaymentStatus status = PaymentStatus.COMPLETED,
        double refund = 0,
        String? review}) =>
    PaymentEntity(
      id: id,
      appointmentId: 'a1',
      amount: amount,
      paymentMethod: PaymentMethod.CASH,
      status: status,
      refundAmount: refund,
      createdAt: at,
      reviewRequired: review,
    );

/// 12.07: el saldo trae el historial de pagos para el detalle de la cita.
void main() {
  const params = AppointmentBalanceParams(appointmentId: 'a1', total: 100000);

  test('historial del más antiguo al más reciente, con todos los estados',
      () async {
    final repo = _Repo([
      _payment('p3', 20000, at: DateTime.utc(2030, 1, 3)),
      _payment('p1', 50000, at: DateTime.utc(2030, 1, 1), refund: 10000),
      _payment('p-sin-fecha', 5000, status: PaymentStatus.FAILED),
      _payment('p2', 30000, at: DateTime.utc(2030, 1, 2), review: 'OVERPAID'),
    ]);
    final balance = (await GetAppointmentBalanceUseCase(repo)(params))
        .getOrElse(() => throw StateError('Left'));

    expect(balance.payments.map((p) => p.id),
        ['p1', 'p2', 'p3', 'p-sin-fecha']);
    // Cuentan los COMPLETED netos y sin revisión: 40.000 + 20.000.
    expect(balance.paid, 60000);
    expect(balance.outstanding, 40000);
    expect(balance.paidFraction, closeTo(0.6, 1e-9));
  });

  test('paidFraction se acota a 0–1 y es 0 sin total', () {
    expect(const AppointmentBalance(total: 0, paid: 0).paidFraction, 0);
    expect(const AppointmentBalance(total: 100, paid: 150).paidFraction, 1);
  });

  test('el historial no entra en la igualdad (el saldo es total y pagado)',
      () {
    expect(
        AppointmentBalance(
            total: 100, paid: 50, payments: [_payment('x', 50)]),
        const AppointmentBalance(total: 100, paid: 50));
  });
}
