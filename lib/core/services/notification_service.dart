// lib/core/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationService._internal() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Inicializar timezone
    tz_init.initializeTimeZones();

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
      print('Notification payload: ${response.payload}');
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
    // Verificar si la hora programada ya pasó
    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) {
      print(
          'Warning: Attempting to schedule notification for past time: $scheduledTime');
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

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'appointment_reminders',
      'Recordatorios de Citas',
      channelDescription: 'Notificaciones para recordatorios de citas',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iOSPlatformChannelSpecifics = DarwinNotificationDetails();

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      print('Notification scheduled successfully for: $scheduledTime');
    } catch (e) {
      print('Error scheduling notification: $e');
      // Mostrar la notificación inmediatamente como fallback
      await showNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );
    }
  }

  // Mostrar una notificación inmediata
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'appointment_reminders',
      'Recordatorios de Citas',
      channelDescription: 'Notificaciones para recordatorios de citas',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iOSPlatformChannelSpecifics = DarwinNotificationDetails();

    final platformChannelSpecifics = NotificationDetails(
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
}
