import 'package:login_signup/features/services/domain/entities/service_entity.dart';

class ServiceModel extends ServiceEntity {
  ServiceModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.duration,
    required super.categoryId,
    required super.color,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] is String
          ? double.parse(json['price'])
          : (json['price'] ?? 0.0).toDouble(),
      duration: json['duration'] is String
          ? int.parse(json['duration'])
          : (json['duration'] ?? 0),
      categoryId: json['categoryId'] ?? '',
      color: json['color'] ?? '#3B82F6',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'categoryId': categoryId,
      'color': color,
    };
  }
}
