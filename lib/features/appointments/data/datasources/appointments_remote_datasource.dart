import 'package:dio/dio.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/entities/manual_reminder.dart';

/// Lo de `/appointments` que sigue yendo al servidor (10.02b): horas libres
/// (con conexión; sin ella se calculan en local) y el recordatorio manual.
/// Leer, agendar, editar, cancelar y completar van por la base local y la
/// bandeja de salida. Sin token ni tenant (los pone el núcleo) y sin
/// try/catch: los errores salen como `DioException` y los traduce `safeCall`.
abstract class AppointmentsRemoteDataSource {
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
