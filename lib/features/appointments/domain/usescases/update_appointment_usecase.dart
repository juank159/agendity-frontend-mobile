import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

class UpdateAppointmentUseCase {
  final AppointmentsRepository repository;

  UpdateAppointmentUseCase(this.repository);

  Future<AppointmentEntity> call(AppointmentEntity appointment) async {
    return await repository.updateAppointment(appointment);
  }
}
