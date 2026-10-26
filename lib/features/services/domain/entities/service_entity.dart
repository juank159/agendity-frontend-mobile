import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/entities/service_price_type.dart';

/// Servicio del catálogo del negocio. Su nombre es único por negocio (sin
/// distinguir mayúsculas).
///
/// - [id] es `null` en un servicio que aún no existe (alta).
/// - [price] en pesos (el backend lo guarda como decimal con 2 decimales).
/// - [duration] en minutos (≥ 1).
/// - [color] es un dato: hex `#RRGGBB` (o `#RGB`), nunca un `Color` de Flutter.
/// - [deposit]: abono requerido (entero).
class ServiceEntity {
  /// Color que pone el backend si el alta no trae uno.
  static const defaultColor = '#1c94f4';

  final String? id;
  final String name;
  final String description;
  final double price;
  final ServicePriceType priceType;
  final int duration;
  final String categoryId;
  final CategoryEntity? category;
  final String color;
  final String? image;
  final bool onlineBooking;
  final int deposit;
  final bool isActive;

  const ServiceEntity({
    this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.priceType = ServicePriceType.fixed,
    required this.duration,
    required this.categoryId,
    this.category,
    this.color = defaultColor,
    this.image,
    this.onlineBooking = false,
    this.deposit = 0,
    this.isActive = true,
  });

  ServiceEntity copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    ServicePriceType? priceType,
    int? duration,
    String? categoryId,
    CategoryEntity? category,
    String? color,
    String? image,
    bool? onlineBooking,
    int? deposit,
    bool? isActive,
  }) =>
      ServiceEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        priceType: priceType ?? this.priceType,
        duration: duration ?? this.duration,
        categoryId: categoryId ?? this.categoryId,
        category: category ?? this.category,
        color: color ?? this.color,
        image: image ?? this.image,
        onlineBooking: onlineBooking ?? this.onlineBooking,
        deposit: deposit ?? this.deposit,
        isActive: isActive ?? this.isActive,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceEntity &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.price == price &&
          other.priceType == priceType &&
          other.duration == duration &&
          other.categoryId == categoryId &&
          other.category == category &&
          other.color == color &&
          other.image == image &&
          other.onlineBooking == onlineBooking &&
          other.deposit == deposit &&
          other.isActive == isActive;

  @override
  int get hashCode => Object.hash(
      id,
      name,
      description,
      price,
      priceType,
      duration,
      categoryId,
      category,
      color,
      image,
      onlineBooking,
      deposit,
      isActive);

  @override
  String toString() => 'ServiceEntity($id, $name)';
}
