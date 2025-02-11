import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

class GetAppointmentsUseCase {
  final AppointmentsRepository repository;

  GetAppointmentsUseCase(this.repository);

  Future<List<AppointmentEntity>> call({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    return await repository.getAppointments(
      startDate: startDate,
      endDate: endDate,
      status: status,
    );
  }
}
