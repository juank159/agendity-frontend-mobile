/// Estado de una cita. Valores idénticos a `AppointmentStatus` del backend
/// (`backend/src/common/enums/status.enum.ts`). Transiciones: ARQUITECTURA §2.1.
enum AppointmentStatus {
  PENDING,
  CONFIRMED,
  COMPLETED,
  CANCELLED;

  String toApi() => name;

  /// Tolerante: ignora mayúsculas/espacios y acepta `CANCELED`. `null` si el
  /// valor falta o no se reconoce (el llamador decide el valor por defecto).
  static AppointmentStatus? fromApi(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toUpperCase();
    if (normalized == 'CANCELED') return AppointmentStatus.CANCELLED;
    for (final status in values) {
      if (status.name == normalized) return status;
    }
    return null;
  }

  /// `COMPLETED` y `CANCELLED` no admiten más cambios.
  bool get isFinal =>
      this == AppointmentStatus.COMPLETED || this == AppointmentStatus.CANCELLED;
}
