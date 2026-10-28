// lib/features/appointments/presentation/controllers/appointment_reminder_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/get_upcoming_appointments_usecase.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../../../core/services/notification_service.dart';
import '../../../whatsapp/data/datasources/whatsapp_launcher.dart';
import 'package:login_signup/features/clients/domain/usecases/get_all_clients_usecase.dart';
import '../../data/datasources/appointments_remote_datasource.dart';

class AppointmentReminderController extends GetxController {
  final GetUpcomingAppointmentsUseCase getUpcomingAppointmentsUseCase;
  final GetAllClientsUseCase getAllClientsUseCase;
  final NotificationService notificationService = NotificationService();

  RxList<AppointmentEntity> upcomingAppointments = <AppointmentEntity>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  
  // ✅ Timer para limpieza automática
  Timer? _cleanupTimer;
  
  // ✅ Referencias para marcar recordatorios como enviados
  late AppointmentsRemoteDataSource _appointmentsDataSource;

  AppointmentReminderController({
    required this.getUpcomingAppointmentsUseCase,
    required this.getAllClientsUseCase,
  });

  @override
  void onInit() {
    super.onInit();
    
    // ✅ Inicializar datasource
    try {
      _appointmentsDataSource = Get.find<AppointmentsRemoteDataSource>();
      print('✅ AppointmentsRemoteDataSource inicializado');
    } catch (e) {
      print('⚠️ Error inicializando AppointmentsRemoteDataSource: $e');
    }
    
    fetchUpcomingAppointments();
    
    // ✅ OPTIMIZACIÓN: Programar limpieza automática cada 5 minutos
    _startPeriodicCleanup();
  }

  // ✅ NUEVA FUNCIONALIDAD: Limpieza periódica de citas pasadas
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanExpiredAppointments();
    });
  }

  // ✅ NUEVA FUNCIONALIDAD: Remover citas que ya pasaron de la lista
  void _cleanExpiredAppointments() async {
    final now = DateTime.now();
    final initialCount = upcomingAppointments.length;
    
    // Crear lista de IDs de notificaciones a cancelar
    final notificationsToCancel = <int>[];
    
    upcomingAppointments.removeWhere((appointment) {
      final appointmentTime = appointment.startTime.toLocal();
      final isPast = appointmentTime.isBefore(now);
      
      if (isPast) {
        print('🗑️ Removiendo cita pasada: ${appointment.clientName} - $appointmentTime');
        notificationsToCancel.add(appointment.id.hashCode);
      }
      
      return isPast;
    });

    // Cancelar todas las notificaciones de citas pasadas
    for (final notificationId in notificationsToCancel) {
      await notificationService.cancelNotification(notificationId);
    }

    final finalCount = upcomingAppointments.length;
    if (initialCount != finalCount) {
      print('🧹 Limpieza completada: ${initialCount - finalCount} citas removidas');
      print('🔔 ${notificationsToCancel.length} notificaciones canceladas');
    }
  }

  Future<void> fetchUpcomingAppointments() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await getUpcomingAppointmentsUseCase(NoParams());

    result.fold(
      (failure) {
        errorMessage.value = failure.message;
      },
      (appointments) {
        // ✅ FILTRAR CITAS FUTURAS - Solo mostrar citas que aún no han pasado
        final now = DateTime.now();
        final futureAppointments = appointments.where((appointment) {
          final appointmentTime = appointment.startTime.toLocal();
          final isFuture = appointmentTime.isAfter(now);
          
          if (!isFuture) {
            print('🕐 Cita filtrada (ya pasó): ${appointment.clientName} - $appointmentTime');
          }
          return isFuture;
        }).toList();

        print('📊 Total citas recibidas: ${appointments.length}');
        print('📊 Citas futuras válidas: ${futureAppointments.length}');

        upcomingAppointments.value = futureAppointments;

        // Programar notificaciones para cada cita futura
        for (var appointment in futureAppointments) {
          _scheduleReminderNotification(appointment);
        }
      },
    );

    isLoading.value = false;
  }

  // Programa una notificación para recordar una cita
  void _scheduleReminderNotification(AppointmentEntity appointment) {
    final appointmentTime = appointment.startTime.toLocal();
    final now = DateTime.now();
    
    // ✅ VERIFICACIÓN ADICIONAL: Solo procesar citas futuras
    if (appointmentTime.isBefore(now)) {
      print('⏰ Omitiendo cita pasada: ${appointment.clientName} - $appointmentTime');
      return;
    }

    // Calcula el tiempo para el recordatorio (30 minutos antes)
    final reminderTime = appointmentTime.subtract(const Duration(minutes: 30));

    print('📅 Programando notificación:');
    print('   Cita: ${appointment.clientName} - $appointmentTime');
    print('   Recordatorio: $reminderTime');

    // Verificar si el tiempo del recordatorio ya pasó
    if (reminderTime.isBefore(now)) {
      // Si el tiempo del recordatorio ya pasó pero la cita aún no ha ocurrido
      if (appointmentTime.isAfter(now)) {
        print('🔔 Mostrando notificación inmediata para cita próxima');
        // Mostrar la notificación inmediatamente
        notificationService.showNotification(
          id: appointment.id.hashCode,
          title: 'Recordatorio de cita próxima',
          body:
              'Cita de ${appointment.serviceTypes.join(", ")} para ${appointment.clientName} a las ${_formatTime(appointmentTime)}',
          payload: appointment.id,
        );
      }
      return;
    }

    // Solo programar si el recordatorio es en el futuro
    print('⏰ Programando notificación para: $reminderTime');
    notificationService.scheduleAppointmentReminder(
      id: appointment.id.hashCode,
      title: 'Recordatorio de cita próxima',
      body:
          'Cita de ${appointment.serviceTypes.join(", ")} para ${appointment.clientName} a las ${_formatTime(appointmentTime)}',
      scheduledTime: reminderTime,
      payload: appointment.id,
    );
  }

// Método auxiliar para formatear la hora correctamente
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final String amPm = hour >= 12 ? 'PM' : 'AM';
    final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final String minuteStr = minute < 10 ? '0$minute' : minute.toString();
    return '$displayHour:$minuteStr $amPm';
  }

  // Abre WhatsApp para enviar un recordatorio
  Future<void> sendAppointmentReminder(AppointmentEntity appointment) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Obtener el cliente para conseguir el número de teléfono
      String clientPhone = '';

      try {
        // Puente hasta la 4.09: busca el teléfono por el nombre del cliente.
        final clients = (await getAllClientsUseCase(NoParams())).fold(
            (failure) => throw Exception(failure.message), (list) => list);
        final client = clients.firstWhere(
          (client) =>
              client.name == appointment.clientName ||
              '${client.name} ${client.lastname}' == appointment.clientName,
          orElse: () => throw Exception('Cliente no encontrado'),
        );

        clientPhone = client.phone;
      } catch (e) {
        errorMessage.value = 'No se pudo encontrar el teléfono del cliente: $e';
        isLoading.value = false;
        return;
      }

      if (clientPhone.isEmpty) {
        errorMessage.value =
            'El cliente no tiene número de teléfono registrado';
        isLoading.value = false;
        return;
      }

      // Usar directamente la fecha sin conversiones adicionales
      final appointmentDate = appointment.startTime
          .toLocal(); // Convertir explícitamente a la zona horaria local

      // Formatear la fecha usando IntlFormat para el día de la semana y el día del mes
      final dateFormatter = DateFormat('EEEE d MMMM', 'es');
      final dateStr = dateFormatter.format(appointmentDate);

      // Extraer los componentes específicos de hora y minutos para evitar problemas de formato
      final hour = appointmentDate.hour;
      final minute = appointmentDate.minute;

      // Crear una representación manual de hora
      final String amPm = hour >= 12 ? 'PM' : 'AM';
      final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final String minuteStr = minute < 10 ? '0$minute' : minute.toString();
      final timeStr = '$displayHour:$minuteStr $amPm';

      // Obtener el servicio (o servicios)
      final serviceName = appointment.serviceTypes.isNotEmpty
          ? appointment.serviceTypes.join(', ')
          : 'servicio programado';

      // Generar el mensaje de recordatorio
      final message = WhatsappLauncher.generateAppointmentReminderMessage(
        clientName: appointment.clientName,
        serviceName: serviceName,
        date: dateStr,
        time: timeStr,
      );

      // Abrir WhatsApp con el mensaje predefinido
      final success = await WhatsappLauncher.openWhatsAppChat(
        clientPhone,
        message,
      );

      if (success) {
        print('✅ Recordatorio enviado exitosamente para: ${appointment.clientName}');
        print('📱 WhatsApp se abrió correctamente, procediendo a marcar como enviado');
        
        // ✅ NUEVA FUNCIONALIDAD: Marcar como enviado y remover de la lista
        await _markReminderAsSent(appointment);
        
        // Cancelar la notificación programada
        await notificationService.cancelNotification(appointment.id.hashCode);
        
        // Remover de la lista local
        final initialCount = upcomingAppointments.length;
        upcomingAppointments.removeWhere((a) => a.id == appointment.id);
        final finalCount = upcomingAppointments.length;
        
        print('🔔 Notificación cancelada');
        print('📋 Cita removida de la lista local ($initialCount -> $finalCount)');
        print('🎯 Cita ${appointment.id} procesada completamente');
      } else {
        print('❌ WhatsApp no se pudo abrir');
        errorMessage.value = 'No se pudo abrir WhatsApp';
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Error al enviar recordatorio: $e';
    }
  }

  // ✅ NUEVO MÉTODO: Marcar recordatorio como enviado en el backend
  Future<void> _markReminderAsSent(AppointmentEntity appointment) async {
    try {
      print('📤 Marcando recordatorio como enviado en el backend para cita: ${appointment.id}');
      
      // ✅ Usar datasource directamente
      final success = await _appointmentsDataSource.markReminderAsSent(appointment.id);
      
      if (success) {
        print('✅ Recordatorio marcado como enviado exitosamente en el backend');
      } else {
        print('⚠️ No se pudo marcar el recordatorio como enviado en el backend');
      }
    } catch (e) {
      print('⚠️ Error marcando recordatorio como enviado: $e');
      // No lanzar error para no bloquear el flujo principal
    }
  }


  // ✅ MÉTODO PÚBLICO: Limpiar manualmente las citas pasadas
  void cleanExpiredAppointments() {
    _cleanExpiredAppointments();
  }

  // ✅ MÉTODO PÚBLICO: Refrescar y limpiar automáticamente
  Future<void> refreshAndClean() async {
    await fetchUpcomingAppointments();
    _cleanExpiredAppointments();
  }

  @override
  void onClose() {
    // ✅ Limpiar timer al cerrar el controlador
    _cleanupTimer?.cancel();
    super.onClose();
  }
}
