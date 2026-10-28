import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/deep_equality.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';

/// Cambios de una cita para `PATCH /appointments/:id` (solo Owner). Solo
/// lleva los campos que cambian: `null` = no tocar.
///
/// Mandar solo lo que cambia evita dos fallos del PATCH completo de antes:
/// - pisar lo que otra persona cambió mientras el formulario estaba abierto
///   (la "carrera de editar");
/// - que cambiar solo las notas vuelva a comprobar el hueco y falle con
///   `SLOT_UNAVAILABLE`/`PROFESSIONAL_INACTIVE` (el backend revisa la agenda
///   si llegan profesional, fecha o servicios, aunque sean los mismos).
class AppointmentChanges {
  final String? clientId;
  final String? professionalId;
  final List<String>? serviceIds;

  /// Nueva hora (de pared, en la zona ACTUAL del negocio: el backend
  /// interpreta así un movimiento, 6.03); mover a OTRA fecha exige que sea
  /// futura y reinicia el recordatorio manual (2.18, 2.21).
  final DateTime? start;

  /// `''` borra las notas.
  final String? notes;

  const AppointmentChanges({
    this.clientId,
    this.professionalId,
    this.serviceIds,
    this.start,
    this.notes,
  });

  /// Lo que difiere entre [original] y los valores del formulario. Servicios:
  /// misma lista en otro orden = sin cambio. Notas: vacías y `null` son lo
  /// mismo; espacios al borde no cuentan.
  factory AppointmentChanges.between(
    AppointmentEntity original, {
    String? clientId,
    String? professionalId,
    List<String>? serviceIds,
    DateTime? start,
    String? notes,
  }) {
    final trimmedNotes = notes?.trim();
    return AppointmentChanges(
      clientId: clientId != null && clientId != original.client.id
          ? clientId
          : null,
      professionalId:
          professionalId != null && professionalId != original.professionalId
              ? professionalId
              : null,
      serviceIds: serviceIds != null &&
              !_sameMembers(serviceIds, original.serviceIds)
          ? List.unmodifiable(serviceIds)
          : null,
      start: start != null && !_sameStart(start, original) ? start : null,
      notes: trimmedNotes != null && trimmedNotes != (original.notes ?? '').trim()
          ? trimmedNotes
          : null,
    );
  }

  /// La hora del formulario es la de la cita: la misma hora de pared (aunque
  /// la cita tenga otra zona, 6.03) o el mismo instante.
  static bool _sameStart(DateTime start, AppointmentEntity original) =>
      start == original.startTime ||
      BusinessTimeZone.toInstant(start)
          .isAtSameMomentAs(original.startInstant);

  bool get isEmpty =>
      clientId == null &&
      professionalId == null &&
      serviceIds == null &&
      start == null &&
      notes == null;

  /// Toca la agenda (el backend vuelve a comprobar disponibilidad).
  bool get touchesSlot =>
      professionalId != null || serviceIds != null || start != null;

  static bool _sameMembers(List<String> a, List<String> b) =>
      a.length == b.length && a.toSet().containsAll(b);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentChanges &&
          other.clientId == clientId &&
          other.professionalId == professionalId &&
          (other.serviceIds == null
              ? serviceIds == null
              : serviceIds != null &&
                  DeepEquality.lists(other.serviceIds!, serviceIds!)) &&
          other.start == start &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(clientId, professionalId,
      serviceIds == null ? null : Object.hashAll(serviceIds!), start, notes);

  @override
  String toString() => 'AppointmentChanges(client: $clientId, '
      'professional: $professionalId, services: $serviceIds, start: $start, '
      'notes: $notes)';
}
