import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_delivery.dart';
import 'package:login_signup/features/reminders/domain/failures/reminder_failures.dart';
import 'package:login_signup/features/reminders/domain/repositories/reminders_repository.dart';

/// Historial de envíos (lo más reciente primero), paginado.
class GetReminderDeliveriesUseCase
    extends UseCase<List<ReminderDelivery>, DeliveriesQuery> {
  static const invalidPage = 'Página fuera de rango';

  final RemindersRepository repository;

  GetReminderDeliveriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ReminderDelivery>>> call(
      DeliveriesQuery params) async {
    if (params.limit < 1 ||
        params.limit > DeliveriesQuery.maxLimit ||
        params.offset < 0) {
      return const Left(InvalidReminderDataFailure(message: invalidPage));
    }
    return repository.getDeliveries(params);
  }
}
