/// Aviso interno para quien usa la app (backend `notifications`), p. ej. el
/// recordatorio automático de una cita (D-05). Solo lectura en la app.
class AppNotification {
  final String id;

  /// Tipo del backend (`APPOINTMENT_REMINDER`…), tal cual.
  final String type;
  final String title;
  final String message;
  final bool read;
  final DateTime? createdAt;

  /// Datos extra (p. ej. `appointmentId`).
  final Map<String, dynamic> metadata;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.read = false,
    this.createdAt,
    this.metadata = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          other.id == id &&
          other.type == type &&
          other.title == title &&
          other.message == message &&
          other.read == read &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, type, title, message, read, createdAt);
}
