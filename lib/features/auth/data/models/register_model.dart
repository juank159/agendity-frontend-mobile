import 'package:login_signup/features/auth/domain/entities/register_entity.dart';
import 'package:login_signup/core/utils/date_codec.dart';

class RegisterModel extends RegisterEntity {
  RegisterModel({
    required super.id,
    required super.name,
    required super.lastname,
    required super.email,
    required super.phone,
    required super.roles,
    super.image,
    super.notificationToken,
    required super.createdAt,
    required super.updatedAt,
  });

  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      id: json['id'],
      name: json['name'],
      lastname: json['lastname'],
      email: json['email'],
      phone: json['phone'],
      roles: (json['roles'] as List)
          .map((role) => role['name'] as String)
          .toList(),
      image: json['image'],
      notificationToken: json['notification_token'],
      createdAt: DateCodec.decode(json['created_at']),
      updatedAt: DateCodec.decode(json['updated_at']),
    );
  }
}
