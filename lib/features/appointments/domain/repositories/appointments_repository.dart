import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';

abstract class AppointmentsRepository {
  Future<List<AppointmentEntity>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
  });
}
