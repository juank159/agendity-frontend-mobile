class LoginResponse {
  final UserEntity user;
  final String token;

  LoginResponse({
    required this.user,
    required this.token,
  });
}

class UserEntity {
  final String id;
  final String name;
  final String lastname;
  final String email;
  final String? phone;
  final String? image;
  final List<String> roles;

  UserEntity({
    required this.id,
    required this.name,
    required this.lastname,
    required this.email,
    this.phone,
    this.image,
    this.roles = const [],
  });
}
