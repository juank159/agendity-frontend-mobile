import 'package:dio/dio.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_changes.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/entities/manual_reminder.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';

/// Rutas `/appointments`. Sin token ni tenant (los pone el núcleo) y sin
/// try/catch: los errores salen como `DioException` y los traduce `safeCall`.
abstract class AppointmentsRemoteDataSource {
  /// `GET /appointments`: las del alcance del usuario, por fecha.
  Future<List<AppointmentModel>> getAppointments(AppointmentsRange range);

  /// `GET /appointments/:id`.
  Future<AppointmentModel> getAppointment(String id);

  /// `POST /appointments` → 201 con la cita completa.
  Future<AppointmentModel> createAppointment(NewAppointment appointment);

  /// `PATCH /appointments/:id` (solo Owner) → la cita completa.
  Future<AppointmentModel> updateAppointment(
      String id, AppointmentChanges changes);

  /// `PATCH /appointments/:id/cancel` → la cita.
  Future<AppointmentModel> cancelAppointment(String id, {String? reason});

  /// `PATCH /appointments/:id/complete` → la cita.
  Future<AppointmentModel> completeAppointment(String id);

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

  /// El backend filtra por `startDate`/`endDate` (desde la 2.34); el
  /// repositorio vuelve a filtrar por instante como red de seguridad.
  @override
  Future<List<AppointmentModel>> getAppointments(
      AppointmentsRange range) async {
    final response = await _dio.get<List<dynamic>>(
      '/appointments',
      queryParameters: {
        'startDate': DateCodec.encode(range.start),
        'endDate': DateCodec.encode(range.end),
      },
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(AppointmentModel.fromJson)
        .toList();
  }

  @override
  Future<AppointmentModel> getAppointment(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/appointments/$id');
    return AppointmentModel.fromJson(response.data!);
  }

  @override
  Future<AppointmentModel> createAppointment(NewAppointment appointment) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/appointments',
      data: NewAppointmentModel.toJson(appointment),
    );
    return AppointmentModel.fromJson(response.data!);
  }

  @override
  Future<AppointmentModel> updateAppointment(
      String id, AppointmentChanges changes) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/appointments/$id',
      data: AppointmentChangesModel.toJson(changes),
    );
    return AppointmentModel.fromJson(response.data!);
  }

  @override
  Future<AppointmentModel> cancelAppointment(String id,
      {String? reason}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/appointments/$id/cancel',
      data: {if (reason != null) 'cancellation_reason': reason},
    );
    return AppointmentModel.fromJson(response.data!);
  }

  @override
  Future<AppointmentModel> completeAppointment(String id) async {
    final response =
        await _dio.patch<Map<String, dynamic>>('/appointments/$id/complete');
    return AppointmentModel.fromJson(response.data!);
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
