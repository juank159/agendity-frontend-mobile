class EmployeeEntity {
  final String id;
  final String name;
  final String lastname;
  final String email;
  final String phone;
  final String? image;
  final bool isActive;
  final List<RoleEntity> roles;

  EmployeeEntity({
    required this.id,
    required this.name,
    required this.lastname,
    required this.email,
    required this.phone,
    this.image,
    required this.isActive,
    required this.roles,
  });
}

class RoleEntity {
  final String id;
  final String name;
  final String? image;
  final String? route;

  RoleEntity({
    required this.id,
    required this.name,
    this.image,
    this.route,
  });
}
