import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  CategoryModel({
    required String id,
    required String name,
  }) : super(id: id, name: name);

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
