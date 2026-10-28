import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login_signup/shared/widgets/whatsapp_icon.dart';
import '../../domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_status_ui.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentEntity appointment;
  final VoidCallback onSendReminder;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onSendReminder,
  });

  @override
  Widget build(BuildContext context) {
    // Convertir a zona horaria local
    final appointmentDate = appointment.startTime.toLocal();

    // Formatear la fecha
    final dateFormatter = DateFormat('EEEE d MMMM', 'es');
    final dateStr = dateFormatter.format(appointmentDate);

    // Extraer componentes de hora para visualización correcta
    final hour = appointmentDate.hour;
    final minute = appointmentDate.minute;
    final String amPm = hour >= 12 ? 'PM' : 'AM';
    final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final String minuteStr = minute < 10 ? '0$minute' : minute.toString();
    final timeStr = '$displayHour:$minuteStr $amPm';

    // Obtener el nombre del servicio
    final serviceName = appointment.serviceNames.isNotEmpty
        ? appointment.serviceNames.join(', ')
        : 'Servicio programado';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar del cliente (usando iniciales)
                CircleAvatar(
                  radius: 25,
                  backgroundColor: appointment.primaryColor,
                  child: Text(
                    appointment.clientName.isNotEmpty
                        ? appointment.clientName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),

                // Información de la cita
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.clientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            timeStr, // Ahora usando la hora correcta
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.payment, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: appointment.paymentStatus.colorsOf(context).color
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              appointment.paymentStatus.label,
                              style: TextStyle(
                                color: appointment.paymentStatus.colorsOf(context).color,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botón para enviar recordatorio
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSendReminder,
                icon: const WhatsappIcon(
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text('Enviar recordatorio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // Color de WhatsApp
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
