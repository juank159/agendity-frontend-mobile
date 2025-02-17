import 'dart:convert';

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
    String? status,
  }) async {
    try {
      final token = await localStorage.getToken();

      // Primero intentar sin parámetros
      print('Intentando obtener citas sin parámetros...');

      final baseResponse = await dio.get(
        '/appointments',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'tenant-id': _extractTenantId(token!),
          },
        ),
      );

      print('Respuesta base: ${baseResponse.statusCode}');
      print('Datos base: ${baseResponse.data}');

      // Si funciona sin parámetros, intentar con parámetros
      if (baseResponse.statusCode == 200 &&
          startDate != null &&
          endDate != null) {
        print('Intentando con parámetros de fecha...');

        final filteredResponse = await dio.get(
          '/appointments',
          queryParameters: {
            'startDate': startDate.toUtc().toIso8601String(),
            'endDate': endDate.toUtc().toIso8601String(),
            if (status != null) 'status': status,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'tenant-id': _extractTenantId(token),
            },
          ),
        );

        if (filteredResponse.statusCode == 200) {
          return _parseAppointments(filteredResponse.data);
        }
      }

      // Si llegamos aquí, usar la respuesta base
      if (baseResponse.statusCode == 200) {
        return _parseAppointments(baseResponse.data);
      }

      throw DioException(
        requestOptions: baseResponse.requestOptions,
        response: baseResponse,
        error: 'Failed to load appointments',
      );
    } catch (e) {
      print('Error loading appointments: $e');
      rethrow;
    }
  }

  List<AppointmentModel> _parseAppointments(dynamic data) {
    try {
      final List<dynamic> appointments = data is List ? data : [data];
      return appointments
          .map((json) => AppointmentModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error parsing appointments: $e');
      rethrow;
    }
  }

  String _extractTenantId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length > 1) {
        final payload = String.fromCharCodes(
            base64Url.decode(base64Url.normalize(parts[1])));
        final decodedPayload = json.decode(payload);
        final tenantId = decodedPayload['tenant_id'] ?? '';
        print('Tenant ID extraído: $tenantId');
        return tenantId;
      }
    } catch (e) {
      print('Error extrayendo tenant_id: $e');
    }
    return '';
  }

  Future<AppointmentModel> createAppointment(
      AppointmentModel appointment) async {
    try {
      final token = await localStorage.getToken();

      // Construir el payload
      final data = {
        'client_id': appointment.clientId,
        'professional_id': appointment.professionalId,
        'service_ids': appointment.serviceIds,
        'owner_id': appointment.ownerId,
        'date': appointment.startTime.toUtc().toIso8601String(),
        'notes': appointment.notes ?? ''
      };

      print('=== CREATE APPOINTMENT DEBUG ===');
      print('Token: $token');
      print('Tenant ID: ${_extractTenantId(token!)}');
      print('URL: ${dio.options.baseUrl}/appointments');
      print('Data a enviar: $data');

      final response = await dio.post(
        '/appointments',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'tenant-id': _extractTenantId(token),
          },
        ),
      );

      print('=== RESPONSE DEBUG ===');
      print('Status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AppointmentModel.fromJson(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to create appointment',
      );
    } catch (e) {
      print('=== ERROR DEBUG ===');
      print('Error tipo: ${e.runtimeType}');
      if (e is DioException) {
        print('DioError type: ${e.type}');
        print('DioError message: ${e.message}');
        print('DioError response status: ${e.response?.statusCode}');
        print('DioError response data: ${e.response?.data}');
        print('DioError requestOptions: ${e.requestOptions.path}');
        print('DioError requestOptions headers: ${e.requestOptions.headers}');
        print('DioError requestOptions data: ${e.requestOptions.data}');
      } else {
        print('Error general: $e');
      }
      rethrow;
    }
  }

  Future<AppointmentModel> updateAppointment(
      AppointmentModel appointment) async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.put(
        '/appointments/${appointment.id}',
        data: appointment.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
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
      print('Error updating appointment: $e');
      rethrow;
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.delete(
        '/appointments/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to delete appointment',
        );
      }
    } catch (e) {
      print('Error deleting appointment: $e');
      rethrow;
    }
  }

  Future<AppointmentModel> getAppointmentById(String id) async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/appointments/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
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
      print('Error getting appointment: $e');
      rethrow;
    }
  }
}
