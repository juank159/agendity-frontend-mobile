import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

class AppointmentsRepositoryImpl implements AppointmentsRepository {
  final AppointmentsRemoteDataSource remoteDataSource;

  AppointmentsRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<AppointmentEntity>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await remoteDataSource.getAppointments(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error in repository: $e');
      throw Exception('Repository Error: $e');
    }
  }
}
