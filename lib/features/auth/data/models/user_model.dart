import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/auth/domain/entities/user_entity.dart';

/// DTO del `user` de las respuestas de auth (`transformUserResponse` del
/// backend: el usuario sin secretos y `roles` como `[{name}]`).
class UserModel {
  final String id;
  final String name;
  final String lastname;
  final String email;
  final String? phone;
  final String? image;
  final List<String> roles;
  final bool isEmailVerified;

  const UserModel({
    required this.id,
    required this.name,
    required this.lastname,
    required this.email,
    this.phone,
    this.image,
    this.roles = const [],
    this.isEmailVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: JsonRead.asString(json['id']),
        name: JsonRead.asString(json['name']),
        lastname: JsonRead.asString(json['lastname']),
        email: JsonRead.asString(json['email']),
        phone: JsonRead.asOptionalString(json['phone']),
        image: JsonRead.asOptionalString(json['image']),
        roles: [
          if (json['roles'] case final List<dynamic> roles)
            for (final role in roles)
              if (_roleName(role) case final name?) name,
        ],
        isEmailVerified:
            JsonRead.asBool(json['is_email_verified'], fallback: false),
      );

  /// `{name: 'Owner'}` (lo normal) o `'Owner'`.
  static String? _roleName(Object? role) => switch (role) {
        Map() => JsonRead.asOptionalString(role['name']),
        String() => JsonRead.asOptionalString(role),
        _ => null,
      };

  UserEntity toEntity() => UserEntity(
        id: id,
        name: name,
        lastname: lastname,
        email: email,
        phone: phone,
        image: image,
        roles: List.unmodifiable(roles),
        isEmailVerified: isEmailVerified,
      );
}

/// Respuesta de login, registro y Google: `{user, token}`. Sin `token` o sin
/// `user.id` es una respuesta inválida (`FormatException` → `ServerFailure`).
class AuthResponseModel {
  final UserModel user;
  final String token;

  const AuthResponseModel({required this.user, required this.token});

  factory AuthResponseModel.fromJson(Map<String, dynamic>? json) {
    final token = JsonRead.asOptionalString(json?['token']);
    final user = JsonRead.asMap(json?['user']);
    if (token == null || user == null) {
      throw const FormatException('Respuesta de autenticación sin token');
    }
    final model = UserModel.fromJson(user);
    if (model.id.isEmpty) {
      throw const FormatException('Respuesta de autenticación sin usuario');
    }
    return AuthResponseModel(user: model, token: token);
  }
}
