import 'package:dartz/dartz.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/payments/domain/entities/appointment_balance.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';

class AppointmentBalanceParams {
  final String appointmentId;

  /// `total_price` de la cita (suma de los precios guardados en ella).
  final double total;

  const AppointmentBalanceParams(
      {required this.appointmentId, required this.total});
}

/// Saldo pendiente de una cita a partir de sus pagos
/// (`GET /payments/appointment/:id`, solo Owner). Para el diálogo de pago
/// cuando la cita tiene un anticipo (`PARTIAL`); con `PENDING` o `COMPLETED`
/// basta `AppointmentEntity.knownBalanceDue`.
class GetAppointmentBalanceUseCase
    extends UseCase<AppointmentBalance, AppointmentBalanceParams> {
  final PaymentRepository repository;

  GetAppointmentBalanceUseCase(this.repository);

  /// Del más antiguo al más reciente (orden estable); sin fecha, al final
  /// en el orden en que llegaron.
  static List<PaymentEntity> _history(List<PaymentEntity> payments) {
    final indexed = [
      for (var i = 0; i < payments.length; i++) (i, payments[i]),
    ];
    indexed.sort((a, b) {
      final x = a.$2.createdAt;
      final y = b.$2.createdAt;
      final byDate = x == null || y == null
          ? (x == null ? 1 : 0) - (y == null ? 1 : 0)
          : x.compareTo(y);
      return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
    });
    return [for (final (_, p) in indexed) p];
  }

  @override
  Future<Either<Failure, AppointmentBalance>> call(
      AppointmentBalanceParams params) async {
    final result = await repository.getAppointmentPayments(params.appointmentId);
    return result.map((payments) {
      final paidCents = payments
          // Un pago en revisión (D-18) no cuenta hasta resolverlo.
          .where((p) => p.status == PaymentStatus.COMPLETED && !p.needsReview)
          .fold<int>(0, (sum, p) => sum + (p.netAmount * 100).round());
      return AppointmentBalance(
          total: params.total,
          paid: paidCents / 100,
          payments: _history(payments));
    });
  }
}
