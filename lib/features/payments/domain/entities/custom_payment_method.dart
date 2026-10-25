/// Método de pago propio del negocio (Nequi, Daviplata…). Lo crea y edita el
/// Owner fuera de la app; aquí solo se elige al registrar un pago.
class CustomPaymentMethod {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final bool isActive;

  const CustomPaymentMethod({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.isActive = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomPaymentMethod &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.icon == icon &&
          other.isActive == isActive;

  @override
  int get hashCode => Object.hash(id, name, description, icon, isActive);
}
