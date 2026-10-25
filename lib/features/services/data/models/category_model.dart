import 'package:login_signup/features/services/domain/entities/category.dart';

class CategoryModel extends CategoryEntity {
  CategoryModel({
    required super.id,
    required super.name,
    required super.description,
    super.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson({bool isCreating = false}) {
    if (isCreating) {
      // Para crear una categoría nueva, solo enviamos name y description
      return {
        'name': name,
        'description': description,
      };
    } else {
      // Para actualizar, enviamos todos los campos
      return {
        'id': id,
        'name': name,
        'description': description,
        'isActive': isActive,
      };
    }
  }
}
