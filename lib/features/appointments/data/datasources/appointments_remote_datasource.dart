import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:login_signup/core/errors/exceptions.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
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

      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toLocal().toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toLocal().toIso8601String();
      }
      if (status != null) {
        queryParams['status'] = status;
      }

      print('=== GET APPOINTMENTS REQUEST ===');
      print('Query params: $queryParams');

      final response = await dio.get(
        '/appointments',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'tenant-id': _extractTenantId(token!),
          },
        ),
      );

      print('=== GET APPOINTMENTS RESPONSE ===');
      print('Status code: ${response.statusCode}');
      print('Data count: ${(response.data as List).length}');

      return _parseAppointments(response.data);
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
        'date': appointment.startTime.toIso8601String(),
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
      final tenantId = _extractTenantId(token!);

      // Construir un payload específico para la actualización
      // que incluye solo los campos necesarios y en el formato correcto
      final updateData = {
        'client_id':
            appointment.clientId, // Asegúrate de que esto no esté vacío
        'professional_id': appointment.professionalId,
        'service_ids': appointment.serviceIds, // Esto es una lista
        'date': appointment.startTime.toIso8601String(),
        'notes': appointment.notes ?? ''
      };

      print('=== UPDATE APPOINTMENT DEBUG ===');
      print('Token: $token');
      print('Tenant ID: $tenantId');
      print('URL: ${dio.options.baseUrl}/appointments/${appointment.id}');
      print('Data a enviar: $updateData');

      final response = await dio.patch(
        '/appointments/${appointment.id}',
        data: updateData, // Usar el objeto específico para actualización
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'tenant-id': tenantId, // Añadir tenant-id al encabezado
          },
        ),
      );

      print('=== UPDATE RESPONSE DEBUG ===');
      print('Status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return AppointmentModel.fromJson(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to update appointment',
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
      print('Error updating appointment: $e');
      rethrow;
    }
  }

  Future<AppointmentModel> updateAppointmentDirect(
    String appointmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await localStorage.getToken();
      final tenantId = _extractTenantId(token!);

      // Sanitizar los datos antes de enviarlos - esto eliminará total_price
      final sanitizedData = _sanitizeRequestData(data);

      print('\n🔄 DATASOURCE: UPDATE APPOINTMENT DIRECT');
      print('👉 URL: ${dio.options.baseUrl}/appointments/$appointmentId');
      print('👉 Método: PATCH');
      print('👉 Headers: Authorization, Content-Type, tenant-id');
      print(
          '👉 Payload: ${json.encode(sanitizedData)}'); // Usar los datos sanitizados

      final response = await dio.patch(
        '/appointments/$appointmentId',
        data: sanitizedData, // Usar los datos sanitizados
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'tenant-id': tenantId,
          },
        ),
      );

      print('\n✅ RESPUESTA DE LA API:');
      print('👉 Status: ${response.statusCode}');
      print('👉 Data: ${json.encode(response.data)}');

      // Asegurar que obtengamos un objeto mapeado
      if (response.data is Map) {
        // Extraer información de clientId y professionalId
        final Map<String, dynamic> responseData = response.data;

        // Añadir IDs para mayor claridad
        if (data.containsKey('professional_id')) {
          print('👉 professionalId enviado: ${data['professional_id']}');
          print(
              '👉 professionalId recibido: ${responseData['professionalId']}');
        }

        if (data.containsKey('client_id')) {
          print('👉 clientId enviado: ${data['client_id']}');
        }
      }

      return AppointmentModel.fromJson(response.data);
    } catch (e) {
      print('\n❌ ERROR EN DATASOURCE:');
      print('👉 Error: $e');

      if (e is DioException) {
        if (e.response != null) {
          print('👉 Status code: ${e.response?.statusCode}');
          print('👉 Response data: ${e.response?.data}');
        }
      }

      rethrow;
    }
  }

  Map<String, dynamic> _sanitizeRequestData(Map<String, dynamic> data) {
    // Crear una copia para no modificar el original
    final sanitizedData = Map<String, dynamic>.from(data);

    // Eliminar campos que el backend no acepta
    sanitizedData.remove('total_price');

    // Sanitizar textos para cualquier campo que pueda tener emojis
    if (sanitizedData.containsKey('notes')) {
      sanitizedData['notes'] = _sanitizeText(sanitizedData['notes'].toString());
    }

    return sanitizedData;
  }

  String _sanitizeText(String text) {
    try {
      // Verificar si hay caracteres inválidos
      return text;
    } catch (e) {
      // Eliminar emojis y caracteres problemáticos
      return text
          .replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true), "")
          .replaceAll(RegExp(r'[\u{1F300}-\u{1F5FF}]', unicode: true), "")
          .replaceAll(RegExp(r'[\u{1F680}-\u{1F6FF}]', unicode: true), "")
          .replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), "")
          .replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), "")
          .trim();
    }
  }

// Función auxiliar para sanitizar datos
  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitizedData = Map<String, dynamic>.from(data);

    // Sanitizar client_id y professional_id
    if (sanitizedData.containsKey('client_id')) {
      sanitizedData['client_id'] = sanitizedData['client_id'].toString();
    }

    if (sanitizedData.containsKey('professional_id')) {
      sanitizedData['professional_id'] =
          sanitizedData['professional_id'].toString();
    }

    return sanitizedData;
  }

  // Añadir este método a tu AppointmentsRemoteDataSource
  Future<Map<String, dynamic>> getProfessionalById(String id) async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/professionals/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'tenant-id': _extractTenantId(token!),
          },
        ),
      );

      if (response.statusCode == 200) {
        print('Professional data loaded: ${response.data}');
        return response.data;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to get professional',
      );
    } catch (e) {
      print('Error getting professional: $e');
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

  Future<List<AppointmentEntity>> getUpcomingAppointments() async {
    try {
      final token = await localStorage.getToken();

      // Obtener la fecha actual y la fecha de mañana para filtrar
      final now = DateTime.now();
      final tomorrow = now.add(Duration(days: 1));

      // Formatear las fechas como cadenas ISO8601
      final startDateStr = now.toIso8601String();
      final endDateStr = tomorrow.toIso8601String();

      final response = await dio.get(
        '/appointments',
        queryParameters: {
          'startDate': startDateStr,
          'endDate': endDateStr,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> appointmentsJson = response.data;
        return appointmentsJson
            .map((json) => AppointmentEntity(
                  id: json['id'],
                  title: json['title'] ?? 'Cita',
                  startTime: DateTime.parse(json['date']),
                  endTime: DateTime.parse(json['date'])
                      .add(Duration(hours: 1)), // Estimar hora de fin
                  clientName: json['client']?['name'] ?? 'Cliente',
                  serviceTypes: _extractServiceNames(json),
                  status: json['status'] ?? 'PENDING',
                  totalPrice: json['total_price']?.toString() ?? '0',
                  paymentStatus: json['payment_status'],
                  notes: json['notes'],
                  colors: null, // Ajustar según los datos disponibles
                  ownerId: json['ownerId'],
                  professionalId: json['professionalId'],
                ))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to load upcoming appointments',
          statusCode: response.statusCode ?? 0,
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Error retrieving upcoming appointments: ${e.toString()}',
      );
    }
  }

// Método auxiliar para extraer nombres de servicios
  List<String> _extractServiceNames(Map<String, dynamic> json) {
    if (json['services'] != null && json['services'] is List) {
      return (json['services'] as List)
          .map((service) => service['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    }
    return [];
  }
}
