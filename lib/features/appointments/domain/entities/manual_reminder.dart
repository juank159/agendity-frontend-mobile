/// Recordatorio manual listo para abrir en WhatsApp
/// (`POST /appointments/:id/send-reminder`, D-05). El teléfono sale de la
/// relación de la cita en el backend; el texto, de su plantilla.
class ManualReminder {
  final String appointmentId;
  final String clientId;
  final String phone;
  final String message;

  /// Enlace `wa.me` con el número normalizado y el texto.
  final String whatsappUrl;

  const ManualReminder({
    required this.appointmentId,
    required this.clientId,
    required this.phone,
    required this.message,
    required this.whatsappUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManualReminder &&
          other.appointmentId == appointmentId &&
          other.clientId == clientId &&
          other.phone == phone &&
          other.message == message &&
          other.whatsappUrl == whatsappUrl;

  @override
  int get hashCode =>
      Object.hash(appointmentId, clientId, phone, message, whatsappUrl);
}
