/// Un servicio dentro de una cita (backend: `services[]` de la cita, 2.29).
class AppointmentServiceLine {
  /// Duración que cuenta el backend para un servicio sin duración
  /// (`DEFAULT_SERVICE_DURATION_MINUTES` de `appointment-slot.ts`).
  static const defaultDurationMinutes = 30;

  final String serviceId;
  final String name;

  /// Minutos que ocupa en la agenda (> 0; sin duración = 30, como el backend).
  final int durationMinutes;

  /// Color del servicio en hexadecimal (`#1c94f4`); `null` si no tiene.
  final String? color;

  /// Precio cobrado EN ESTA CITA (`appointment_price`): la foto del precio al
  /// agendarla. Es el que suma el total y el que se muestra.
  final double price;

  /// Precio actual del servicio en el catálogo (`price`); puede diferir de
  /// [price] si el servicio cambió de precio después de agendar.
  final double? currentPrice;

  const AppointmentServiceLine({
    required this.serviceId,
    required this.name,
    this.durationMinutes = defaultDurationMinutes,
    this.color,
    required this.price,
    this.currentPrice,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentServiceLine &&
          other.serviceId == serviceId &&
          other.name == name &&
          other.durationMinutes == durationMinutes &&
          other.color == color &&
          other.price == price &&
          other.currentPrice == currentPrice;

  @override
  int get hashCode =>
      Object.hash(serviceId, name, durationMinutes, color, price, currentPrice);

  @override
  String toString() => 'AppointmentServiceLine($serviceId, $name, $price)';
}
