import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';

abstract class AppointmentsRepository {
  Future<List<AppointmentEntity>> getAppointments(
      {DateTime? startDate, DateTime? endDate, String? status});

  Future<AppointmentEntity> createAppointment(AppointmentEntity appointment);
  Future<AppointmentEntity> updateAppointment(AppointmentEntity appointment);
  Future<void> deleteAppointment(String id);
  Future<AppointmentEntity> getAppointmentById(String id);
  Future<Either<Failure, List<AppointmentEntity>>> getUpcomingAppointments();
  Future<AppointmentEntity?> updateAppointmentDirect({
    required String appointmentId,
    required Map<String, dynamic> data,
  });
}
