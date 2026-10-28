import 'dart:async';
import 'package:get/get.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_upcoming_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/mark_reminder_sent_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/prepare_reminder_usecase.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../../../core/services/notification_service.dart';
import '../../../whatsapp/data/datasources/whatsapp_launcher.dart';

class AppointmentReminderController extends GetxController {
  final GetUpcomingAppointmentsUseCase getUpcomingAppointmentsUseCase;
  final PrepareReminderUseCase prepareReminderUseCase;
  final MarkReminderSentUseCase markReminderSentUseCase;
  final NotificationService notificationService = NotificationService();

  RxList<AppointmentEntity> upcomingAppointments = <AppointmentEntity>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  
  // ✅ Timer para limpieza automática
  Timer? _cleanupTimer;
  
  AppointmentReminderController({
    required this.getUpcomingAppointmentsUseCase,
    required this.prepareReminderUseCase,
    required this.markReminderSentUseCase,
  });

  @override
  void onInit() {
    super.onInit();
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
              'Cita de ${appointment.serviceNames.join(", ")} para ${appointment.clientName} a las ${_formatTime(appointmentTime)}',
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
          'Cita de ${appointment.serviceNames.join(", ")} para ${appointment.clientName} a las ${_formatTime(appointmentTime)}',
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

  /// Abre WhatsApp con el recordatorio que prepara el backend (teléfono por
  /// la cita, nunca por nombre) y, si se abrió, lo marca como enviado.
  Future<void> sendAppointmentReminder(AppointmentEntity appointment) async {
    isLoading.value = true;
    errorMessage.value = '';

    final prepared = await prepareReminderUseCase(appointment.id);
    final reminder = prepared.fold((failure) {
      errorMessage.value = failure.message;
      return null;
    }, (reminder) => reminder);
    if (reminder == null) {
      isLoading.value = false;
      return;
    }

    final opened =
        await WhatsappLauncher.openWhatsAppChat(reminder.phone, reminder.message);
    if (!opened) {
      errorMessage.value = 'No se pudo abrir WhatsApp';
      isLoading.value = false;
      return;
    }

    // Si marcar falla, el recordatorio ya salió: no se bloquea al usuario.
    await markReminderSentUseCase(appointment.id);
    await notificationService.cancelNotification(appointment.id.hashCode);
    upcomingAppointments.removeWhere((a) => a.id == appointment.id);
    isLoading.value = false;
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
