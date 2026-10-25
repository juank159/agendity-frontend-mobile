import 'package:login_signup/features/payments/domain/entities/custom_payment_method.dart';

/// DTO de `/custom-payment-methods` (backend: `CustomPaymentMethod`;
/// `isActive` en camelCase, fechas en snake_case y sin uso en la app).
class CustomPaymentMethodModel {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final bool isActive;

  const CustomPaymentMethodModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.isActive = true,
  });

  factory CustomPaymentMethodModel.fromJson(Map<String, dynamic> json) {
    final isActive = json['isActive'];
    return CustomPaymentMethodModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString().trim() ?? '',
      description: _optional(json['description']),
      icon: _optional(json['icon']),
      isActive: isActive is bool ? isActive : isActive != 'false',
    );
  }

  factory CustomPaymentMethodModel.fromEntity(CustomPaymentMethod entity) =>
      CustomPaymentMethodModel(
        id: entity.id,
        name: entity.name,
        description: entity.description,
        icon: entity.icon,
        isActive: entity.isActive,
      );

  CustomPaymentMethod toEntity() => CustomPaymentMethod(
        id: id,
        name: name,
        description: description,
        icon: icon,
        isActive: isActive,
      );

  static String? _optional(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
