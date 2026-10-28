/// Cliente de una cita, tal como viene en la cita (`client` de
/// `GET /appointments`). Es una vista mínima: la ficha completa es
/// `ClientEntity` (feature clients).
class AppointmentClient {
  final String id;
  final String name;
  final String lastname;

  /// `null` si el cliente no tiene teléfono. El recordatorio manual lo pide
  /// al backend (`send-reminder`), nunca lo busca por nombre.
  final String? phone;

  const AppointmentClient({
    required this.id,
    required this.name,
    this.lastname = '',
    this.phone,
  });

  String get fullName => '$name $lastname'.trim();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentClient &&
          other.id == id &&
          other.name == name &&
          other.lastname == lastname &&
          other.phone == phone;

  @override
  int get hashCode => Object.hash(id, name, lastname, phone);

  @override
  String toString() => 'AppointmentClient($id, $fullName)';
}
