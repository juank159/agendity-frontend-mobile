/// Configuración del negocio (`GET /settings`, 6.01). Hoy solo su zona
/// horaria IANA (D-15): todas las horas del negocio se interpretan y se
/// muestran en ella.
class BusinessSettings {
  final String timeZone;

  const BusinessSettings({required this.timeZone});

  BusinessSettings copyWith({String? timeZone}) =>
      BusinessSettings(timeZone: timeZone ?? this.timeZone);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessSettings && other.timeZone == timeZone;

  @override
  int get hashCode => timeZone.hashCode;

  @override
  String toString() => 'BusinessSettings(timeZone: $timeZone)';
}
