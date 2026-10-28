import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/services/data/models/category_model.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/entities/service_price_type.dart';

/// DTO de `/services` (backend: `Service`, todo en camelCase).
///
/// - `price` es decimal en Postgres y llega como texto (`"45000.00"`).
/// - `category` llega en `GET /services` y al editar; el alta no la trae.
class ServiceModel {
  final String? id;
  final String name;
  final String description;
  final double price;
  final ServicePriceType priceType;
  final int duration;
  final String categoryId;
  final CategoryModel? category;
  final String color;
  final String? image;
  final bool onlineBooking;
  final int deposit;
  final bool isActive;

  const ServiceModel({
    this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.priceType = ServicePriceType.fixed,
    required this.duration,
    required this.categoryId,
    this.category,
    this.color = ServiceEntity.defaultColor,
    this.image,
    this.onlineBooking = false,
    this.deposit = 0,
    this.isActive = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'];
    final category = rawCategory is Map
        ? CategoryModel.fromJson(Map<String, dynamic>.from(rawCategory))
        : null;
    final color = JsonRead.asOptionalString(json['color']);
    return ServiceModel(
      id: JsonRead.asOptionalString(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: JsonRead.asDouble(json['price']),
      priceType:
          ServicePriceType.fromApi(json['priceType']) ?? ServicePriceType.fixed,
      duration: JsonRead.asInt(json['duration']),
      categoryId:
          JsonRead.asOptionalString(json['categoryId']) ?? category?.id ?? '',
      category: category,
      color: color ?? ServiceEntity.defaultColor,
      image: JsonRead.asOptionalString(json['image']),
      onlineBooking: JsonRead.asBool(json['onlineBooking'], fallback: false),
      deposit: JsonRead.asInt(json['deposit']),
      isActive: JsonRead.asBool(json['isActive'], fallback: true),
    );
  }

  factory ServiceModel.fromEntity(ServiceEntity entity) => ServiceModel(
        id: entity.id,
        name: entity.name,
        description: entity.description,
        price: entity.price,
        priceType: entity.priceType,
        duration: entity.duration,
        categoryId: entity.categoryId,
        category: entity.category == null
            ? null
            : CategoryModel.fromEntity(entity.category!),
        color: entity.color,
        image: entity.image,
        onlineBooking: entity.onlineBooking,
        deposit: entity.deposit,
        isActive: entity.isActive,
      );

  ServiceEntity toEntity() => ServiceEntity(
        id: id,
        name: name,
        description: description,
        price: price,
        priceType: priceType,
        duration: duration,
        categoryId: categoryId,
        category: category?.toEntity(),
        color: color,
        image: image,
        onlineBooking: onlineBooking,
        deposit: deposit,
        isActive: isActive,
      );

  /// Cuerpo de `POST /services` y `PATCH /services/:id` (`CreateServiceDto`):
  /// sin `id` ni `isActive`, que el DTO no admite; `image` solo si hay.
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'price': price,
        'priceType': priceType.toApi(),
        'duration': duration,
        'categoryId': categoryId,
        'color': color,
        if (image != null) 'image': image,
        'onlineBooking': onlineBooking,
        'deposit': deposit,
      };
}
