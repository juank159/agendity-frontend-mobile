import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';

class EmployeeModel extends EmployeeEntity {
  EmployeeModel({
    required super.id,
    required super.name,
    required super.lastname,
    required super.email,
    required super.phone,
    super.image,
    required super.isActive,
    required super.roles,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'],
      name: json['name'],
      lastname: json['lastname'],
      email: json['email'],
      phone: json['phone'],
      image: json['image'],
      isActive: json['isActive'],
      roles: (json['roles'] as List)
          .map((role) => RoleModel.fromJson(role))
          .toList(),
    );
  }
}

class RoleModel extends RoleEntity {
  RoleModel({
    required super.id,
    required super.name,
    super.image,
    super.route,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      route: json['route'],
    );
  }
}
