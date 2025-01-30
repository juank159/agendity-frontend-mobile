import 'package:login_signup/features/services/data/models/category_model.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';

class ServiceModel extends ServiceEntity {
  ServiceModel({
    String? id,
    required String name,
    required String description,
    required double price,
    required String priceType,
    required int duration,
    required String categoryId,
    required String color,
    CategoryEntity? category,
    String? image,
    bool onlineBooking = false,
    int deposit = 0,
    bool isActive = true,
  }) : super(
          id: id,
          name: name,
          description: description,
          price: price,
          priceType: priceType,
          duration: duration,
          categoryId: categoryId,
          category: category,
          color: color,
          image: image,
          onlineBooking: onlineBooking,
          deposit: deposit,
          isActive: isActive,
        );

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      priceType: json['priceType'] ?? 'Precio fijo',
      duration: int.parse(json['duration'].toString()),
      categoryId: json['categoryId'],
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
      color: json['color'],
      image: json['image'],
      onlineBooking: json['onlineBooking'] ?? false,
      deposit: int.parse(json['deposit']?.toString() ?? '0'),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'priceType': priceType,
      'duration': duration,
      'categoryId': categoryId,
      'color': color,
      'image': image,
      'onlineBooking': onlineBooking,
      'deposit': deposit,
    };
  }
}
