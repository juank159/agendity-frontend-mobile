import 'package:dartz/dartz.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/payments/domain/entities/appointment_balance.dart';
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

  @override
  Future<Either<Failure, AppointmentBalance>> call(
      AppointmentBalanceParams params) async {
    final result = await repository.getAppointmentPayments(params.appointmentId);
    return result.map((payments) {
      final paidCents = payments
          .where((p) => p.status == PaymentStatus.COMPLETED)
          .fold<int>(0, (sum, p) => sum + (p.netAmount * 100).round());
      return AppointmentBalance(total: params.total, paid: paidCents / 100);
    });
  }
}
