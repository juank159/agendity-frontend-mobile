import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';

abstract class AppointmentsRepository {
  Future<List<AppointmentEntity>> getAppointments(
      {DateTime? startDate, DateTime? endDate, String? status});

  Future<AppointmentEntity> createAppointment(AppointmentEntity appointment);
  Future<AppointmentEntity> updateAppointment(AppointmentEntity appointment);
  Future<void> deleteAppointment(String id);
  Future<AppointmentEntity> getAppointmentById(String id);
}
