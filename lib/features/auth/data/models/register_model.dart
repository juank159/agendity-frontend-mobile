import 'package:login_signup/features/auth/domain/entities/register_entity.dart';

class RegisterModel extends RegisterEntity {
  RegisterModel({
    required String id,
    required String name,
    required String lastname,
    required String email,
    required String phone,
    required List<String> roles,
    String? image,
    String? notificationToken,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          name: name,
          lastname: lastname,
          email: email,
          phone: phone,
          roles: roles,
          image: image,
          notificationToken: notificationToken,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

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
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
