import 'package:dio/dio.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class AppointmentsRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;

  AppointmentsRemoteDataSource({
    required this.dio,
    required this.localStorage,
  });

  Future<List<AppointmentModel>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await localStorage.getToken();

      Map<String, dynamic> queryParameters = {};
      if (startDate != null && endDate != null) {
        queryParameters = {
          'startDate': startDate.toUtc().toIso8601String(),
          'endDate': endDate.toUtc().toIso8601String(),
        };
      }

      final response = await dio.get(
        '/appointments',
        queryParameters: queryParameters,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => AppointmentModel.fromJson(json))
            .toList();
      }

      throw Exception('Failed to load appointments');
    } catch (e) {
      print('Error loading appointments: $e');
      throw Exception('Error loading appointments: $e');
    }
  }
}
