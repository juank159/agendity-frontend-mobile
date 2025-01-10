import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.name,
    required super.lastname,
    required super.email,
    super.phone,
    super.image,
    super.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user']; // Cambiado de 'userData' a 'user'
    return UserModel(
      id: userData['id'],
      name: userData['name'],
      lastname: userData['lastname'],
      email: userData['email'],
      phone: userData['phone'],
      image: userData['image'],
      roles: List<String>.from(
        userData['roles'].map((role) => role['name']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': {
        // Cambiado de 'userData' a 'user' para mantener consistencia
        'id': id,
        'name': name,
        'lastname': lastname,
        'email': email,
        'phone': phone,
        'image': image,
        'roles': roles.map((role) => {'name': role}).toList(),
      }
    };
  }
}
