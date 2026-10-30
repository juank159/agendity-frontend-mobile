/// Origen de una cita (9.01, D-17): `APP` (la agendó el negocio en la app) o
/// `WEB` (reserva de un cliente desde el link público; entra `PENDING` y el
/// negocio la confirma). Valores = API.
// ignore_for_file: constant_identifier_names
enum AppointmentSource {
  APP,
  WEB;

  String toApi() => name;

  /// Tolerante (mayúsculas y espacios); `null` si no se reconoce.
  static AppointmentSource? fromApi(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toUpperCase();
    for (final source in values) {
      if (source.name == normalized) return source;
    }
    return null;
  }
}
