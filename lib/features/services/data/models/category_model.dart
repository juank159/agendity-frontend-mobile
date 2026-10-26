import 'package:login_signup/features/services/domain/entities/category.dart';

/// DTO de `/categories` (backend: `Category`; `isActive` en camelCase).
/// `GET /categories` trae `services: [...]` (activos o no): de ahí sale
/// `serviceCount`. La categoría anidada en un servicio no los trae (`null`).
class CategoryModel {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final int? serviceCount;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.isActive = true,
    this.serviceCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final services = json['services'];
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isActive: _bool(json['isActive'], fallback: true),
      serviceCount: services is List ? services.length : null,
    );
  }

  factory CategoryModel.fromEntity(CategoryEntity entity) => CategoryModel(
        id: entity.id,
        name: entity.name,
        description: entity.description,
        isActive: entity.isActive,
        serviceCount: entity.serviceCount,
      );

  CategoryEntity toEntity() => CategoryEntity(
        id: id,
        name: name,
        description: description,
        isActive: isActive,
        serviceCount: serviceCount,
      );

  /// Cuerpo de `POST /categories` y de `PATCH /categories/:id` al editar
  /// (`CreateCategoryDto`: sin `id`; el estado va aparte).
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
      };

  static bool _bool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value == null) return fallback;
    return value.toString().toLowerCase() != 'false';
  }
}
