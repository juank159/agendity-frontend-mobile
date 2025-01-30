import 'package:login_signup/features/services/domain/entities/category.dart';

class CategoryModel extends CategoryEntity {
  CategoryModel({
    required String id,
    required String name,
    required String description,
    bool isActive = true,
  }) : super(
          id: id,
          name: name,
          description: description,
          isActive: isActive,
        );

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
    };
  }
}
