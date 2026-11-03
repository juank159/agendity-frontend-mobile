import 'package:dio/dio.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/entities/manual_reminder.dart';

/// Lo de `/appointments` que va al servidor: horas libres (con conexión; sin
/// ella se calculan en local), el recordatorio manual y, desde 13.05,
/// **agendar y mover con conexión** (estricto: un choque vuelve como error y
/// no se guarda nada). Leer, cancelar, completar y lo que se hace sin
/// conexión van por la base local y la bandeja de salida. Sin token ni
/// tenant (los pone el núcleo) y sin try/catch: los errores salen como
/// `DioException` y los traduce `safeCall`.
abstract class AppointmentsRemoteDataSource {
  /// `POST /appointments` con el id generado en la app (UUID v7) → la cita
  /// con la forma de la API (la misma que guarda la sincronización).
  Future<Map<String, dynamic>> createAppointment(
      String id, Map<String, dynamic> body);

  /// `PATCH /appointments/:id` (solo los campos que cambian) → la cita.
  Future<Map<String, dynamic>> updateAppointment(
      String id, Map<String, dynamic> body);

  /// `GET /appointments/available-slots` → inicios con el offset del negocio.
  Future<List<DateTime>> getAvailableSlots(AvailableSlotsQuery query);

  /// `POST /appointments/:id/send-reminder`.
  Future<ManualReminder> prepareReminder(String id);

  /// `PATCH /appointments/:id/reminder/mark-sent` → hora del primer envío.
  Future<DateTime> markReminderSent(String id);
}

class AppointmentsRemoteDataSourceImpl implements AppointmentsRemoteDataSource {
  final Dio _dio;

  /// Debe ser el Dio `tag: apiClientTag` (token y errores del núcleo).
  AppointmentsRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> createAppointment(
      String id, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>('/appointments',
        data: {'id': id, ...body});
    return response.data!;
  }

  @override
  Future<Map<String, dynamic>> updateAppointment(
      String id, Map<String, dynamic> body) async {
    final response =
        await _dio.patch<Map<String, dynamic>>('/appointments/$id', data: body);
    return response.data!;
  }

  @override
  Future<List<DateTime>> getAvailableSlots(AvailableSlotsQuery query) async {
    final response = await _dio.get<List<dynamic>>(
      '/appointments/available-slots',
      queryParameters: {
        'professional_id': query.professionalId,
        'date': DateCodec.encodeDay(query.day),
        'service_ids': query.serviceIds.join(','),
        if (query.stepMinutes != null) 'step': query.stepMinutes,
      },
    );
    return response.data!.map((slot) => DateCodec.decode(slot as String)).toList();
  }

  @override
  Future<ManualReminder> prepareReminder(String id) async {
    final response = await _dio
        .post<Map<String, dynamic>>('/appointments/$id/send-reminder');
    return ManualReminderModel.fromJson(response.data!);
  }

  @override
  Future<DateTime> markReminderSent(String id) async {
    final response = await _dio
        .patch<Map<String, dynamic>>('/appointments/$id/reminder/mark-sent');
    return DateCodec.tryDecode(response.data?['sentAt']) ??
        BusinessTimeZone.now();
  }
}
