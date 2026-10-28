/// Rol de una cuenta. El backend solo envía el nombre: `Admin`, `Owner` o
/// `Employee`.
class RoleEntity {
  static const owner = 'Owner';
  static const employee = 'Employee';

  final String name;

  const RoleEntity(this.name);

  bool get isOwner => name == owner;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RoleEntity && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}
