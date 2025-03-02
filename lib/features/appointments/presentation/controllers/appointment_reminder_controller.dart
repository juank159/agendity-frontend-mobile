// lib/features/appointments/presentation/controllers/appointment_reminder_controller.dart
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/get_upcoming_appointments_usecase.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../../../core/services/notification_service.dart';
import '../../../whatsapp/data/datasources/whatsapp_launcher.dart';
import '../../../clients/data/datasources/clients_remote_datasource.dart';

class AppointmentReminderController extends GetxController {
  final GetUpcomingAppointmentsUseCase getUpcomingAppointmentsUseCase;
  final ClientsRemoteDataSource clientsRemoteDataSource;
  final NotificationService notificationService = NotificationService();

  RxList<AppointmentEntity> upcomingAppointments = <AppointmentEntity>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;

  AppointmentReminderController({
    required this.getUpcomingAppointmentsUseCase,
    required this.clientsRemoteDataSource,
  });

  @override
  void onInit() {
    super.onInit();
    fetchUpcomingAppointments();
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
        upcomingAppointments.value = appointments;

        // Programar notificaciones para cada cita
        for (var appointment in appointments) {
          _scheduleReminderNotification(appointment);
        }
      },
    );

    isLoading.value = false;
  }

  // Programa una notificación para recordar una cita
  void _scheduleReminderNotification(AppointmentEntity appointment) {
    // Calcula el tiempo para el recordatorio (30 minutos antes)
    final appointmentTime = appointment.startTime.toLocal();
    final reminderTime = appointmentTime.subtract(const Duration(minutes: 30));

    // Verificar explícitamente si el tiempo del recordatorio ya pasó
    final now = DateTime.now();
    if (reminderTime.isBefore(now)) {
      // Si el tiempo del recordatorio ya pasó pero la cita aún no ha ocurrido
      if (appointmentTime.isAfter(now)) {
        // Mostrar la notificación inmediatamente en lugar de programarla
        notificationService.showNotification(
          id: appointment.id.hashCode,
          title: 'Recordatorio de cita próxima',
          body:
              'Cita de ${appointment.serviceTypes.join(", ")} para ${appointment.clientName} a las ${_formatTime(appointmentTime)}',
          payload: appointment.id,
        );
      }
      return; // No intentar programar una notificación para un tiempo pasado
    }

    // Solo programar si el recordatorio es en el futuro
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
        // Obtener los clientes y buscar el que coincida con clientName
        final clients = await clientsRemoteDataSource.getClients();
        final client = clients.firstWhere(
          (client) =>
              client['name'] == appointment.clientName ||
              '${client['name']} ${client['lastname']}' ==
                  appointment.clientName,
          orElse: () => throw Exception('Cliente no encontrado'),
        );

        clientPhone = client['phone'];
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
        // Si se abrió WhatsApp correctamente, eliminar la cita de la lista
        upcomingAppointments.removeWhere((a) => a.id == appointment.id);
      } else {
        errorMessage.value = 'No se pudo abrir WhatsApp';
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Error al enviar recordatorio: $e';
    }
  }
}
