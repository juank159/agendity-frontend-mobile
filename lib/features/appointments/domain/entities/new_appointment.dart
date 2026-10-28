import 'package:login_signup/core/utils/deep_equality.dart';

/// Datos para agendar una cita (`POST /appointments`). El negocio sale del
/// JWT y el precio lo calcula el backend con el catálogo: aquí no van.
class NewAppointment {
  final String clientId;

  /// Un Employee solo puede agendarse a sí mismo (si no, 403 del backend).
  final String professionalId;

  /// Al menos uno y sin repetidos (reglas del DTO).
  final List<String> serviceIds;

  /// Instante de inicio; debe ser futuro (`APPOINTMENT_IN_PAST`).
  final DateTime start;
  final String? notes;

  const NewAppointment({
    required this.clientId,
    required this.professionalId,
    required this.serviceIds,
    required this.start,
    this.notes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewAppointment &&
          other.clientId == clientId &&
          other.professionalId == professionalId &&
          DeepEquality.lists(other.serviceIds, serviceIds) &&
          other.start == start &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(
      clientId, professionalId, Object.hashAll(serviceIds), start, notes);
}
