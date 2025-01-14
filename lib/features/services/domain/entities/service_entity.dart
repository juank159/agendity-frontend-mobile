class ServiceEntity {
  final String id;
  final String name;
  final String description;
  final double
      price; // El backend lo envía como String, pero nosotros lo manejamos como double
  final int duration;
  final String categoryId;
  final String color;

  ServiceEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.categoryId,
    required this.color,
  });

  // Opcional: método para convertir el precio a String cuando sea necesario
  String get priceAsString => price.toString();
}
