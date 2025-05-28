// lib/features/employees/domain/entities/role_entity.dart
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
