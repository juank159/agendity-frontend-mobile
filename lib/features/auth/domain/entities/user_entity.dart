import 'package:login_signup/core/utils/deep_equality.dart';

/// Usuario autenticado, tal como lo devuelve el backend tras el login, el
/// registro o el login con Google (`{user, token}`; el token lo guarda la
/// sesión, no la entidad).
class UserEntity {
  final String id;
  final String name;
  final String lastname;
  final String email;

  /// `null` en las cuentas de Google (2.10: el teléfono es opcional).
  final String? phone;
  final String? image;

  /// Nombres de rol: `Owner`, `Employee`, `Admin` (`SessionRole`).
  final List<String> roles;
  final bool isEmailVerified;

  const UserEntity({
    required this.id,
    required this.name,
    required this.lastname,
    required this.email,
    this.phone,
    this.image,
    this.roles = const [],
    this.isEmailVerified = false,
  });

  String get fullName => [name, lastname].where((p) => p.isNotEmpty).join(' ');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          other.id == id &&
          other.name == name &&
          other.lastname == lastname &&
          other.email == email &&
          other.phone == phone &&
          other.image == image &&
          other.isEmailVerified == isEmailVerified &&
          DeepEquality.lists(other.roles, roles);

  @override
  int get hashCode => Object.hash(id, name, lastname, email, phone, image,
      isEmailVerified, Object.hashAll(roles));
}
