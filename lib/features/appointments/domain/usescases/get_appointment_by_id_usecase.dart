import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

class GetAppointmentByIdUseCase {
  final AppointmentsRepository repository;

  GetAppointmentByIdUseCase(this.repository);

  Future<AppointmentEntity> call(String id) async {
    return await repository.getAppointmentById(id);
  }
}
