import 'package:login_signup/features/services/domain/entities/category.dart';

class ServiceEntity {
  final String? id;
  final String name;
  final String description;
  final double price;
  final String priceType;
  final int duration;
  final String categoryId;
  final CategoryEntity? category;
  final String color;
  final String? image;
  final bool onlineBooking;
  final int deposit;
  final bool isActive;

  ServiceEntity({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    this.priceType = 'Precio fijo',
    required this.duration,
    required this.categoryId,
    this.category,
    required this.color,
    this.image,
    this.onlineBooking = false,
    this.deposit = 0,
    this.isActive = true,
  });

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
