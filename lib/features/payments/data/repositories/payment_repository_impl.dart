import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/features/payments/data/datasources/payment_remote_datasource.dart';
import 'package:login_signup/features/payments/data/models/payment_model.dart';
import 'package:login_signup/features/payments/domain/entities/custom_payment_method.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/payments/domain/failures/payment_failures.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _remote;

  PaymentRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaymentEntity>> createPayment(PaymentEntity payment) =>
      safeCall(
        () async => (await _remote.createPayment(PaymentModel.fromEntity(payment)))
            .toEntity(),
        refine: _refine,
      );

  @override
  Future<Either<Failure, List<CustomPaymentMethod>>>
      getActiveCustomPaymentMethods() => safeCall(() async =>
          (await _remote.getActiveCustomPaymentMethods())
              .map((m) => m.toEntity())
              .toList());

  @override
  Future<Either<Failure, List<PaymentEntity>>> getAppointmentPayments(
          String appointmentId) =>
      safeCall(() async => (await _remote.getAppointmentPayments(appointmentId))
          .map((m) => m.toEntity())
          .toList());

  /// Al crear un pago, `INVALID_STATE_TRANSITION` solo significa "cita
  /// cancelada" (`statusAfterPayment` del backend).
  static Failure _refine(Failure failure) =>
      failure.code == ApiErrorCode.invalidStateTransition
          ? AppointmentNotPayableFailure(
              message: failure.message,
              code: failure.code,
              statusCode: failure.statusCode,
              details: failure.details,
            )
          : failure;
}
