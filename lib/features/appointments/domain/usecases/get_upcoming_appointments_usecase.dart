import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

/// Citas de los próximos días que necesitan el recordatorio manual:
/// pendientes o confirmadas (nunca canceladas ni completadas), futuras y sin
/// recordatorio enviado. Ordenadas por hora.
class GetUpcomingAppointmentsUseCase
    extends UseCase<List<AppointmentEntity>, NoParams> {
  static const window = Duration(days: 7);

  final AppointmentsRepository repository;
  final DateTime Function() _now;

  GetUpcomingAppointmentsUseCase(this.repository, {DateTime Function()? now})
      : _now = now ?? BusinessTimeZone.now;

  @override
  Future<Either<Failure, List<AppointmentEntity>>> call(
      NoParams params) async {
    final now = _now();
    final result = await repository
        .getAppointments(AppointmentsRange(start: now, end: now.add(window)));
    return result.map((appointments) => appointments
        .where((a) => a.needsReminderAt(now))
        .toList()
      ..sort((a, b) => a.startInstant.compareTo(b.startInstant)));
  }
}
