import 'package:dio/dio.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

class AppointmentsRepositoryImpl implements AppointmentsRepository {
  final AppointmentsRemoteDataSource remoteDataSource;

  AppointmentsRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<AppointmentEntity>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      return await remoteDataSource.getAppointments(
        startDate: startDate,
        endDate: endDate,
        status: status,
      );
    } on DioException catch (e) {
      throw AppointmentException(
        message: e.message ?? 'Error getting appointments',
        code: e.response?.statusCode,
      );
    } catch (e) {
      throw AppointmentException(message: e.toString());
    }
  }

  @override
  Future<AppointmentEntity> createAppointment(
      AppointmentEntity appointment) async {
    try {
      if (appointment is! AppointmentModel) {
        throw AppointmentException(
          message: 'Invalid appointment type',
        );
      }

      return await remoteDataSource.createAppointment(appointment);
    } on DioException catch (e) {
      throw AppointmentException(
        message: e.message ?? 'Error creating appointment',
        code: e.response?.statusCode,
      );
    } catch (e) {
      throw AppointmentException(message: e.toString());
    }
  }

  @override
  Future<AppointmentEntity> updateAppointment(
      AppointmentEntity appointment) async {
    try {
      if (appointment is! AppointmentModel) {
        throw AppointmentException(
          message: 'Invalid appointment type',
        );
      }

      return await remoteDataSource.updateAppointment(appointment);
    } on DioException catch (e) {
      throw AppointmentException(
        message: e.message ?? 'Error updating appointment',
        code: e.response?.statusCode,
      );
    } catch (e) {
      throw AppointmentException(message: e.toString());
    }
  }

  @override
  Future<void> deleteAppointment(String id) async {
    try {
      await remoteDataSource.deleteAppointment(id);
    } on DioException catch (e) {
      throw AppointmentException(
        message: e.message ?? 'Error deleting appointment',
        code: e.response?.statusCode,
      );
    } catch (e) {
      throw AppointmentException(message: e.toString());
    }
  }

  @override
  Future<AppointmentEntity> getAppointmentById(String id) async {
    try {
      return await remoteDataSource.getAppointmentById(id);
    } on DioException catch (e) {
      throw AppointmentException(
        message: e.message ?? 'Error getting appointment',
        code: e.response?.statusCode,
      );
    } catch (e) {
      throw AppointmentException(message: e.toString());
    }
  }
}

class AppointmentException implements Exception {
  final String message;
  final int? code;

  AppointmentException({required this.message, this.code});

  @override
  String toString() =>
      'AppointmentException: $message ${code != null ? '(Code: $code)' : ''}';
}
