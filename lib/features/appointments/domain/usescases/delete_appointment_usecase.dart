import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

class DeleteAppointmentUseCase {
  final AppointmentsRepository repository;

  DeleteAppointmentUseCase(this.repository);

  Future<void> call(String id) async {
    await repository.deleteAppointment(id);
  }
}
