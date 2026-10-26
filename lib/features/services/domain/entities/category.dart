/// Categoría del catálogo del negocio (salones: "Cejas", "Uñas"…).
///
/// [serviceCount] es cuántos servicios (activos o no) tiene, si el backend
/// los envió (`GET /categories` sí; la categoría anidada en un servicio no):
/// `null` = desconocido. Una categoría con servicios no se puede borrar
/// (`CategoryHasServicesFailure`).
class CategoryEntity {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final int? serviceCount;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.description = '',
    this.isActive = true,
    this.serviceCount,
  });

  /// `true` solo si se sabe que tiene servicios.
  bool get hasServices => (serviceCount ?? 0) > 0;

  CategoryEntity copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    int? serviceCount,
  }) =>
      CategoryEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        isActive: isActive ?? this.isActive,
        serviceCount: serviceCount ?? this.serviceCount,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryEntity &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.isActive == isActive &&
          other.serviceCount == serviceCount;

  @override
  int get hashCode =>
      Object.hash(id, name, description, isActive, serviceCount);

  @override
  String toString() => 'CategoryEntity($id, $name)';
}
