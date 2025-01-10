class RegisterEntity {
  final String id;
  final String name;
  final String lastname;
  final String email;
  final String phone;
  final List<String> roles;
  final String? image;
  final String? notificationToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  RegisterEntity({
    required this.id,
    required this.name,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.roles,
    this.image,
    this.notificationToken,
    required this.createdAt,
    required this.updatedAt,
  });
}
