// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:ui';
// import 'dart:io';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:login_signup/core/config/env_config.dart';
// import 'package:login_signup/shared/local_storage/local_storage.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz_init;
// import 'package:login_signup/core/services/notification_service.dart';
// import 'package:login_signup/core/routes/routes.dart';

// class NotificationModule {
//   static FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;

//   static Future<void> init() async {
//     try {
//       print("NotificationModule: Iniciando inicialización");

//       // Inicializar timezone
//       tz_init.initializeTimeZones();

//       // Primero registramos el plugin de notificaciones locales
//       _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//       Get.put<FlutterLocalNotificationsPlugin>(
//           _flutterLocalNotificationsPlugin!,
//           permanent: true);
//       print("NotificationModule: Plugin de notificaciones locales registrado");

//       // Configurar notificaciones locales básicas
//       await _initializeLocalNotifications(_flutterLocalNotificationsPlugin!);

//       // Luego registramos nuestro servicio de notificaciones
//       // (Importante: El constructor no debe acceder a Firebase)
//       final notificationService = NotificationService();
//       Get.put<NotificationService>(notificationService, permanent: true);
//       print("NotificationModule: Servicio de notificaciones registrado");

//       // NO inicializamos Firebase aquí, eso se hace en main.dart
//       print("NotificationModule: Inicialización completada");
//     } catch (e) {
//       print("ERROR NotificationModule: Error en inicialización: $e");
//       print("ERROR NotificationModule: Stack trace: ${StackTrace.current}");
//       rethrow;
//     }
//   }

//   // Este método se debe llamar después de que Firebase esté inicializado
//   static Future<void> initializeFirebase() async {
//     try {
//       print("NotificationModule: Inicializando Firebase para notificaciones");

//       // Recuperamos el servicio ya registrado
//       final notificationService = Get.find<NotificationService>();

//       // Ahora sí inicializamos Firebase Messaging en el servicio
//       await notificationService.initializeFirebaseMessaging();

//       // Configurar opciones de presentación en primer plano (importante para iOS)
//       await FirebaseMessaging.instance
//           .setForegroundNotificationPresentationOptions(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//       print(
//           "NotificationModule: Opciones de presentación en primer plano configuradas");

//       // Verificar token APNS para iOS
//       if (Platform.isIOS) {
//         FirebaseMessaging.instance.getAPNSToken().then((token) {
//           print("APNS Token: $token");
//           if (token == null) {
//             print("APNS Token es null - problemas con la configuración APNS");
//           }
//         });
//       }

//       // Configurar manejadores para diferentes escenarios
//       _setupFirebaseMessagingHandlers();

//       print(
//           "NotificationModule: Firebase para notificaciones inicializado correctamente");
//     } catch (e) {
//       print(
//           "ERROR NotificationModule: Error inicializando Firebase para notificaciones: $e");
//       print("ERROR NotificationModule: Stack trace: ${StackTrace.current}");
//       rethrow;
//     }
//   }

//   // Método para inicializar notificaciones locales
//   static Future<void> _initializeLocalNotifications(
//       FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
//     print("NotificationModule: Configurando notificaciones locales");

//     try {
//       // Configuración para Android
//       const AndroidInitializationSettings androidSettings =
//           AndroidInitializationSettings('@mipmap/ic_launcher');

//       // Configuración para iOS
//       const DarwinInitializationSettings iosSettings =
//           DarwinInitializationSettings(
//         requestAlertPermission: true,
//         requestBadgePermission: true,
//         requestSoundPermission: true,
//         requestProvisionalPermission: true, // Para notificaciones provisionales
//         defaultPresentAlert: true,
//         defaultPresentBadge: true,
//         defaultPresentSound: true,
//       );

//       // Configuración general
//       const InitializationSettings initSettings = InitializationSettings(
//         android: androidSettings,
//         iOS: iosSettings,
//       );

//       // Inicializar el plugin
//       await flutterLocalNotificationsPlugin.initialize(
//         initSettings,
//         onDidReceiveNotificationResponse: (NotificationResponse response) {
//           print(
//               "NotificationModule: Notificación seleccionada: ${response.payload}");

//           // Si tienes un ID de cita, puedes usarlo para ir directamente a esa cita
//           if (response.payload != null && response.payload!.isNotEmpty) {
//             print(
//                 "NotificationModule: Navegando a cita específica: ${response.payload}");
//             Get.toNamed(GetRoutes.notifications,
//                 arguments: {'appointmentId': response.payload});
//           } else {
//             // Si no hay ID, solo ir a la pantalla general de citas
//             print("NotificationModule: Navegando a lista de citas");
//             Get.toNamed(GetRoutes.notifications);
//           }
//         },
//       );

//       // Configurar canales para Android
//       await _setupNotificationChannels(flutterLocalNotificationsPlugin);

//       print(
//           "NotificationModule: Notificaciones locales configuradas correctamente");
//     } catch (e) {
//       print(
//           "ERROR NotificationModule: Error configurando notificaciones locales: $e");
//       print("ERROR NotificationModule: Stack trace: ${StackTrace.current}");
//       rethrow;
//     }
//   }

//   // Configurar canales de notificación para Android
//   static Future<void> _setupNotificationChannels(
//       FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
//     print("NotificationModule: Configurando canales de notificación");

//     try {
//       // Canal de alta prioridad para recordatorios de citas
//       const AndroidNotificationChannel appointmentChannel =
//           AndroidNotificationChannel(
//         'appointment_reminders',
//         'Recordatorios de Citas',
//         description: 'Notificaciones para recordatorios de citas',
//         importance: Importance.max,
//         playSound: true,
//         enableVibration: true,
//         showBadge: true,
//         enableLights: true,
//         ledColor: Color.fromARGB(255, 255, 0, 0), // Luz LED roja
//       );

//       // Registro del canal en Android
//       final androidPlugin =
//           flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
//               AndroidFlutterLocalNotificationsPlugin>();

//       if (androidPlugin != null) {
//         await androidPlugin.createNotificationChannel(appointmentChannel);

//         // También creamos un grupo para nuestras notificaciones
//         await androidPlugin.createNotificationChannelGroup(
//             const AndroidNotificationChannelGroup('appointment_group', 'Citas',
//                 description:
//                     'Todas las notificaciones relacionadas con citas'));

//         print("NotificationModule: Canal de notificación creado correctamente");
//       } else {
//         print(
//             "NotificationModule: No se pudo obtener la implementación para Android");
//       }
//     } catch (e) {
//       print("ERROR NotificationModule: Error configurando canales: $e");
//       print("ERROR NotificationModule: Stack trace: ${StackTrace.current}");
//     }
//   }

//   // Configurar manejadores para Firebase Messaging
//   static void _setupFirebaseMessagingHandlers() {
//     try {
//       // 1. Cuando la app está en primer plano
//       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//         print("NotificationModule: ⭐ MENSAJE EN PRIMER PLANO RECIBIDO ⭐");
//         print("NotificationModule: Mensaje ID: ${message.messageId}");
//         _showForegroundNotification(message);
//       });

//       // 2. Cuando la app está en segundo plano y se toca la notificación
//       FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//         print("NotificationModule: ⭐ MENSAJE ABIERTO DESDE SEGUNDO PLANO ⭐");
//         print("NotificationModule: Mensaje ID: ${message.messageId}");
//         Get.toNamed(GetRoutes.notifications);
//       });

//       print(
//           "NotificationModule: Manejadores de Firebase Messaging configurados correctamente");
//     } catch (e) {
//       print("ERROR NotificationModule: Error configurando manejadores: $e");
//       print("ERROR NotificationModule: Stack trace: ${StackTrace.current}");
//     }
//   }

//   static void _showForegroundNotification(RemoteMessage message) {
//     try {
//       print("NotificationModule: RECIBIDO MENSAJE DE FIREBASE:");
//       print("NotificationModule: DATA: ${message.data}");
//       if (message.notification != null) {
//         print(
//             "NotificationModule: NOTIFICATION: ${message.notification?.title} - ${message.notification?.body}");
//       }

//       // Determinar título y cuerpo, ya sea del objeto notification o de los datos
//       String title = message.notification?.title ??
//           message.data['title'] ??
//           'Recordatorio de Cita';

//       String body = message.notification?.body ??
//           message.data['body'] ??
//           'Tienes una cita programada';

//       if (message.data.containsKey('clientName') &&
//           message.data.containsKey('serviceName')) {
//         // Si tenemos los datos específicos, construimos un mensaje personalizado
//         String clientName = message.data['clientName'] ?? '';
//         String serviceName = message.data['serviceName'] ?? '';
//         String time = message.data['time'] ?? '';

//         body = 'Cliente: $clientName - Servicio: $serviceName' +
//             (time.isNotEmpty ? ' - Hora: $time' : '');
//       }

//       final flutterLocalNotificationsPlugin =
//           Get.find<FlutterLocalNotificationsPlugin>();

//       // Android configuration
//       final androidDetails = AndroidNotificationDetails(
//         'appointment_reminders',
//         'Recordatorios de Citas',
//         channelDescription: 'Notificaciones para recordatorios de citas',
//         importance: Importance.max,
//         priority: Priority.high,
//         fullScreenIntent: true,
//         visibility: NotificationVisibility.public,
//       );

//       // iOS configuration
//       const iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//         interruptionLevel: InterruptionLevel.timeSensitive,
//       );

//       // Extraer el ID de la cita si está disponible
//       String appointmentId = message.data['appointmentId'] ?? '';

//       // Mostrar notificación
//       flutterLocalNotificationsPlugin.show(
//         DateTime.now().millisecondsSinceEpoch.remainder(100000),
//         title,
//         body,
//         NotificationDetails(
//           android: androidDetails,
//           iOS: iosDetails,
//         ),
//         payload: appointmentId,
//       );

//       print(
//           "NotificationModule: Notificación mostrada correctamente: '$title - $body'");
//     } catch (e) {
//       print("ERROR NotificationModule: Error mostrando notificación: $e");
//       print("ERROR NotificationModule: Stack trace: ${StackTrace.current}");
//     }
//   }

// // Añade este método para asegurar que las notificaciones se reciban correctamente
//   static Future<void> ensureNotificationsWork() async {
//     try {
//       // 1. Configurar opciones de presentación para iOS
//       await FirebaseMessaging.instance
//           .setForegroundNotificationPresentationOptions(
//               alert: true, badge: true, sound: true);

//       // 2. Solicitar permisos explícitamente (importante en iOS)
//       final settings = await FirebaseMessaging.instance.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//         provisional: false,
//       );
//       print(
//           "Estado de autorización de notificaciones: ${settings.authorizationStatus}");

//       // 3. Re-suscribir al tema de recordatorios
//       await FirebaseMessaging.instance
//           .subscribeToTopic('appointment_reminders');

//       // 4. Reforzar los listeners de mensajes
//       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//         print("⭐⭐⭐ NOTIFICACIÓN RECIBIDA EN PRIMER PLANO ⭐⭐⭐");
//         _showForegroundNotification(message);
//       });

//       // 5. Verificar el token y actualizarlo en el backend
//       final fcmToken = await FirebaseMessaging.instance.getToken();
//       if (fcmToken != null) {
//         print(
//             "Token FCM: ${fcmToken.substring(0, min(20, fcmToken.length))}...");

//         // Actualizar en el backend
//         final dio = Get.find<Dio>();
//         final localStorage = Get.find<LocalStorage>();
//         final authToken = await localStorage.getToken();

//         if (authToken != null && authToken.isNotEmpty) {
//           try {
//             final response = await dio.patch(
//               '${EnvConfig.apiUrl}/auth/notification-token',
//               data: {'token': fcmToken},
//               options: Options(
//                 headers: {
//                   'Content-Type': 'application/json',
//                   'Accept': 'application/json',
//                   'Authorization': 'Bearer $authToken',
//                 },
//               ),
//             );

//             if (response.statusCode == 200) {
//               print("Token FCM actualizado exitosamente en el backend");
//             }
//           } catch (e) {
//             print("Error actualizando token FCM en backend: $e");
//           }
//         }
//       }

//       print("Configuración de notificaciones completada exitosamente");
//     } catch (e) {
//       print("ERROR configurando notificaciones: $e");
//     }
//   }

//   static Future<void> testNotification() async {
//     print("NotificationModule: Probando notificación...");
//     try {
//       final flutterLocalNotificationsPlugin =
//           Get.find<FlutterLocalNotificationsPlugin>();

//       print("NotificationModule: Plugin de notificaciones encontrado");

//       // Configuración para Android
//       final AndroidNotificationDetails androidDetails =
//           AndroidNotificationDetails(
//         'appointment_reminders',
//         'Recordatorios de Citas',
//         channelDescription: 'Notificaciones para recordatorios de citas',
//         importance: Importance.max,
//         priority: Priority.high,
//         ticker: 'Nueva notificación de prueba',
//         channelShowBadge: true,
//         color: Colors.red,
//         ledColor: Colors.red,
//         ledOnMs: 1000,
//         ledOffMs: 500,
//         enableLights: true,
//         enableVibration: true,
//         playSound: true,
//         fullScreenIntent: true,
//         visibility: NotificationVisibility.public,
//       );

//       print("NotificationModule: Configuración Android creada");

//       // Configuración para iOS
//       const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//         sound: 'default',
//         interruptionLevel:
//             InterruptionLevel.timeSensitive, // Más alta prioridad
//         categoryIdentifier: 'appointment', // Categoría específica
//       );

//       print("NotificationModule: Configuración iOS creada");

//       // Mostrar notificación con ID único
//       print("NotificationModule: Intentando mostrar notificación...");
//       int notificationId =
//           DateTime.now().millisecondsSinceEpoch.remainder(100000);
//       await flutterLocalNotificationsPlugin.show(
//         notificationId,
//         'Prueba de Notificación',
//         'Esta es una notificación de prueba. Si ves esto, las notificaciones están funcionando correctamente: ${DateTime.now()}',
//         NotificationDetails(
//           android: androidDetails,
//           iOS: iosDetails,
//         ),
//         payload: 'test_notification',
//       );

//       print("NotificationModule: Notificación de prueba enviada correctamente");
//     } catch (e) {
//       print(
//           "ERROR NotificationModule: Error mostrando notificación de prueba: $e");
//       print("ERROR NotificationModule: Stack trace: ${StackTrace.current}");
//     }
//   }

//   // Método para probar notificaciones programadas
//   static Future<void> testScheduledNotification() async {
//     print("NotificationModule: Probando notificación programada...");
//     try {
//       final flutterLocalNotificationsPlugin =
//           Get.find<FlutterLocalNotificationsPlugin>();

//       // Configuración Android y iOS (igual que en testNotification)
//       final AndroidNotificationDetails androidDetails =
//           AndroidNotificationDetails(
//         'appointment_reminders',
//         'Recordatorios de Citas',
//         channelDescription: 'Notificaciones para recordatorios de citas',
//         importance: Importance.max,
//         priority: Priority.high,
//         fullScreenIntent: true,
//         playSound: true,
//         enableVibration: true,
//         channelShowBadge: true,
//         color: Colors.orange,
//       );

//       const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//         sound: 'default',
//         interruptionLevel: InterruptionLevel.timeSensitive,
//         categoryIdentifier: 'appointment',
//       );

//       // Programar para 5 segundos en el futuro
//       final DateTime scheduledTime = DateTime.now().add(Duration(seconds: 5));
//       int notificationId =
//           DateTime.now().millisecondsSinceEpoch.remainder(100000);

//       await flutterLocalNotificationsPlugin.zonedSchedule(
//         notificationId,
//         'Notificación Programada',
//         'Esta notificación fue programada para aparecer 5 segundos después: ${DateTime.now()}',
//         tz.TZDateTime.from(scheduledTime, tz.local),
//         NotificationDetails(android: androidDetails, iOS: iosDetails),
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//         uiLocalNotificationDateInterpretation:
//             UILocalNotificationDateInterpretation.absoluteTime,
//         payload: 'test_scheduled_notification',
//       );

//       print(
//           "NotificationModule: Notificación programada para: ${scheduledTime.toString()}");
//     } catch (e) {
//       print("ERROR NotificationModule: Error programando notificación: $e");
//       print("ERROR NotificationModule: Stack trace: ${StackTrace.current}");
//     }
//   }

// // Actualiza el método testBackendNotification en NotificationModule
//   static Future<void> testBackendNotification() async {
//     print(
//         "NotificationModule: Simulando notificación del backend (cita en 5 min)...");

//     // Crear un mensaje como el que enviaría tu backend
//     final message = RemoteMessage(
//       messageId: 'test-backend-${DateTime.now().millisecondsSinceEpoch}',
//       notification: RemoteNotification(
//         title: 'Recordatorio de Cita',
//         body: 'Tienes una cita en 5 minutos con Cliente de Prueba',
//       ),
//       data: {
//         'appointmentId': 'test-appointment-123',
//         'type': 'appointment_reminder',
//         'clientName': 'Cliente de Prueba',
//         'time': '15:30',
//         'timeLeft': '5 minutos'
//       },
//     );

//     // Procesar el mensaje como si viniera del backend
//     _showForegroundNotification(message);

//     print("NotificationModule: Notificación de backend simulada enviada");
//   }

//   // static Future<void> verifyFcmSetup() async {
//   //   try {
//   //     // 1. Obtener e imprimir el token FCM actual
//   //     final fcmToken = await FirebaseMessaging.instance.getToken();
//   //     print("⭐ VERIFICACIÓN FCM ⭐");
//   //     print("Token FCM actual: ${fcmToken ?? 'NO HAY TOKEN'}");

//   //     // 2. Comprobar si estamos recibiendo mensajes en primer plano
//   //     FirebaseMessaging.onMessage.listen((message) {
//   //       print("✅ LISTENER ACTIVO: Mensaje recibido en verificación");
//   //     });

//   //     // 3. Solicitar permisos explícitamente
//   //     final settings = await FirebaseMessaging.instance.requestPermission(
//   //       alert: true,
//   //       badge: true,
//   //       sound: true,
//   //     );
//   //     print("Estado de autorización: ${settings.authorizationStatus}");

//   //     // 4. Configurar opciones de primer plano
//   //     await FirebaseMessaging.instance
//   //         .setForegroundNotificationPresentationOptions(
//   //       alert: true,
//   //       badge: true,
//   //       sound: true,
//   //     );

//   //     // 5. Solo intentar obtener el token APNS en iOS
//   //     if (Platform.isIOS) {
//   //       try {
//   //         final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
//   //         print("Token APNS: ${apnsToken ?? 'NO HAY TOKEN APNS'}");
//   //       } catch (apnsError) {
//   //         // Simplemente registramos el error pero no lo propagamos
//   //         print("Aviso: No se pudo obtener token APNS: $apnsError");
//   //         print(
//   //             "Esto es normal en simuladores de iOS y no afecta la funcionalidad en Android");
//   //       }
//   //     }

//   //     print("✅ Verificación completada. La configuración básica es correcta.");
//   //   } catch (e) {
//   //     print("❌ ERROR en verificación FCM: $e");
//   //     print("Stack trace: ${StackTrace.current}");
//   //   }
//   // }

//   static Future<void> verifyFcmSetup() async {
//     try {
//       // 1. Obtener e imprimir el token FCM actual
//       final fcmToken = await FirebaseMessaging.instance.getToken();
//       print("⭐ VERIFICACIÓN FCM ⭐");
//       print("Token FCM actual: ${fcmToken ?? 'NO HAY TOKEN'}");

//       // 2. Comprobar si estamos recibiendo mensajes en primer plano
//       FirebaseMessaging.onMessage.listen((message) {
//         print("✅ LISTENER ACTIVO: Mensaje recibido en verificación");
//       });

//       // 3. Solicitar permisos explícitamente
//       final settings = await FirebaseMessaging.instance.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//       print("Estado de autorización: ${settings.authorizationStatus}");

//       // 4. Configurar opciones de primer plano
//       await FirebaseMessaging.instance
//           .setForegroundNotificationPresentationOptions(
//         alert: true,
//         badge: true,
//         sound: true,
//       );

//       // 5. Solo intentar obtener el token APNS en iOS, pero sin lanzar error
//       if (Platform.isIOS) {
//         try {
//           final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
//           print("Token APNS: ${apnsToken ?? 'NO HAY TOKEN APNS'}");

//           // Si no hay token APNS, registramos el problema pero continuamos
//           if (apnsToken == null) {
//             print(
//                 "⚠️ ADVERTENCIA: Token APNS es null - Problema de configuración");
//             print("Continuando sin token APNS...");
//           }
//         } catch (apnsError) {
//           // Simplemente registramos el error pero no interrumpimos el flujo
//           print("⚠️ ADVERTENCIA: Error con token APNS: $apnsError");
//           print("Ignorando este error y continuando...");
//         }
//       }

//       print("✅ Verificación FCM completada. Continuando con la aplicación.");
//     } catch (e) {
//       // Registramos el error pero NO lo relanzamos para permitir que la app continúe
//       print("⚠️ ERROR en verificación FCM: $e");
//       print("Stack trace: ${StackTrace.current}");
//       print("Continuando a pesar del error...");
//     }
//   }

//   static Future<void> testLocalNotification() async {
//     try {
//       print("NotificationModule: Probando notificación local...");

//       final flutterLocalNotificationsPlugin =
//           Get.find<FlutterLocalNotificationsPlugin>();

//       // Android configuration
//       final androidDetails = AndroidNotificationDetails(
//         'appointment_reminders',
//         'Recordatorios de Citas',
//         channelDescription: 'Notificaciones para recordatorios de citas',
//         importance: Importance.max,
//         priority: Priority.high,
//         fullScreenIntent: true,
//         styleInformation: const BigTextStyleInformation(
//           'Este es un mensaje de prueba para verificar que las notificaciones locales funcionan correctamente',
//         ),
//       );

//       // iOS configuration
//       const iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//         interruptionLevel: InterruptionLevel.timeSensitive,
//       );

//       // Show notification
//       await flutterLocalNotificationsPlugin.show(
//         999,
//         'Test de Notificación Local',
//         'Si puedes ver esto, las notificaciones locales funcionan correctamente',
//         NotificationDetails(android: androidDetails, iOS: iosDetails),
//         payload: 'test_payload',
//       );

//       print(
//           "NotificationModule: Notificación local de prueba enviada correctamente");
//     } catch (e) {
//       print(
//           "ERROR NotificationModule: Error en test de notificación local: $e");
//       print("ERROR NotificationModule: Stack trace: ${StackTrace.current}");
//     }
//   }

//   // Añade este método después de los otros métodos de prueba
//   static Future<void> forceFcmSetup() async {
//     try {
//       print("NotificationModule: Forzando configuración de FCM");

//       // Esto debe ejecutarse después de que Firebase esté inicializado
//       // 1. Solicitar permisos de notificación
//       final settings = await FirebaseMessaging.instance.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//         provisional: false,
//       );
//       print(
//           "NotificationModule: Estado de permisos: ${settings.authorizationStatus}");

//       // 2. Configurar opciones de presentación para iOS
//       await FirebaseMessaging.instance
//           .setForegroundNotificationPresentationOptions(
//         alert: true,
//         badge: true,
//         sound: true,
//       );

//       // 3. Obtener y mostrar el token FCM
//       final fcmToken = await FirebaseMessaging.instance.getToken();
//       print(
//           "NotificationModule: Token FCM obtenido: ${fcmToken ?? 'NO DISPONIBLE'}");

//       // 4. Reforzar la suscripción a los mensajes
//       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//         print("NotificationModule: ⚡ MENSAJE RECIBIDO desde Firebase");
//         _showForegroundNotification(message);
//       });

//       print("NotificationModule: Configuración de FCM completada");
//       return;
//     } catch (e) {
//       print("ERROR NotificationModule: Error configurando FCM: $e");
//       print("ERROR NotificationModule: Stack trace: ${StackTrace.current}");
//     }
//   }
// }
