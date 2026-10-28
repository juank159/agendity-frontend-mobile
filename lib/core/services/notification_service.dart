// lib/core/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:login_signup/core/utils/app_logger.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationService._internal() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Una sola base de datos de zonas para toda la app (D-15).
    BusinessTimeZone.ensureInitialized();

    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configuración general
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
  }

  Future<void> _onSelectNotification(NotificationResponse response) async {
    // Maneja la acción cuando el usuario toca la notificación
    if (response.payload != null) {
      // Aquí puedes navegar a la pantalla de detalles de la cita
      AppLogger.debug('Notification payload: ${response.payload}');
    }
  }

  // Programar una notificación para una cita próxima
  Future<void> scheduleAppointmentReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // [scheduledTime] es un instante UTC o una hora de pared del negocio
    // (D-15): se programa en su instante real, no en la hora del dispositivo.
    final instant = BusinessTimeZone.toInstant(scheduledTime);
    if (instant.isBefore(BusinessTimeZone.clock())) {
      AppLogger.debug(
          'Notificación en una hora pasada ($scheduledTime): se muestra ya');
      // Opción 1: No hacer nada y retornar
      // return;

      // Opción 2: Mostrar la notificación inmediatamente en su lugar
      return showNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );
    }

    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'appointment_reminders',
      'Recordatorios de Citas',
      channelDescription: 'Notificaciones para recordatorios de citas',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iOSPlatformChannelSpecifics = DarwinNotificationDetails();

    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(instant, tz.UTC),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // ✅ Cambio a inexact para evitar permisos especiales
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      AppLogger.debug('Notification scheduled for: $scheduledTime');
    } catch (e) {
      AppLogger.error('Error scheduling notification', e);
      
      // ✅ FALLBACK MEJORADO: Intentar con modo normal primero
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(instant, tz.UTC),
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.alarmClock, // Modo menos restrictivo
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        AppLogger.debug('Notification scheduled with alarmClock mode');
      } catch (e2) {
        AppLogger.error('Failed with alarmClock mode', e2);
        // Como último recurso, mostrar inmediatamente
        await showNotification(
          id: id,
          title: title,
          body: body,
          payload: payload,
        );
      }
    }
  }

  // Mostrar una notificación inmediata
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'appointment_reminders',
      'Recordatorios de Citas',
      channelDescription: 'Notificaciones para recordatorios de citas',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iOSPlatformChannelSpecifics = DarwinNotificationDetails();

    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // ✅ NUEVO MÉTODO: Cancelar una notificación programada
  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      AppLogger.error('Error cancelling notification $id', e);
    }
  }

  // ✅ NUEVO MÉTODO: Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      AppLogger.error('Error cancelling all notifications', e);
    }
  }
}
