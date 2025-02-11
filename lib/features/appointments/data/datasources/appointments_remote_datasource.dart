import 'package:dio/dio.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class AppointmentsRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;
  static const String endpoint = '/appointments';

  AppointmentsRemoteDataSource({
    required this.dio,
    required this.localStorage,
  });

  Future<List<AppointmentModel>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      final token = await localStorage.getToken();

      final queryParameters = <String, dynamic>{
        if (startDate != null) 'startDate': startDate.toUtc().toIso8601String(),
        if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
        if (status != null) 'status': status,
      };

      final response = await dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => AppointmentModel.fromJson(json)).toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load appointments',
      );
    } catch (e) {
      print('Error loading appointments: $e');
      throw Exception('Error loading appointments: $e');
    }
  }

  Future<AppointmentModel> createAppointment(
      AppointmentModel appointment) async {
    try {
      final token = await localStorage.getToken();

      print('Datos a enviar a API: ${appointment.toJson()}');

      final response = await dio.post(
        endpoint,
        data: appointment.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201) {
        return AppointmentModel.fromJson(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to create appointment',
      );
    } catch (e) {
      print('Error creating appointment: $e');
      throw Exception('Error creating appointment: $e');
    }
  }

  Future<AppointmentModel> updateAppointment(
      AppointmentModel appointment) async {
    try {
      final token = await localStorage.getToken();
      final response = await dio.put(
        '$endpoint/${appointment.id}',
        data: appointment.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return AppointmentModel.fromJson(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to update appointment',
      );
    } catch (e) {
      throw Exception('Error updating appointment: $e');
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      final token = await localStorage.getToken();
      final response = await dio.delete(
        '$endpoint/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to delete appointment',
        );
      }
    } catch (e) {
      throw Exception('Error deleting appointment: $e');
    }
  }

  Future<AppointmentModel> getAppointmentById(String id) async {
    try {
      final token = await localStorage.getToken();
      final response = await dio.get(
        '$endpoint/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return AppointmentModel.fromJson(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to get appointment',
      );
    } catch (e) {
      throw Exception('Error getting appointment: $e');
    }
  }
}
