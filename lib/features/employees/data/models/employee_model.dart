import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';

class EmployeeModel extends EmployeeEntity {
  EmployeeModel({
    required String id,
    required String name,
    required String lastname,
    required String email,
    required String phone,
    String? image,
    required bool isActive,
    required List<RoleEntity> roles,
    List<String>? serviceIds,
    Map<String, Map<String, String>>? schedule,
  }) : super(
          id: id,
          name: name,
          lastname: lastname,
          email: email,
          phone: phone,
          image: image,
          isActive: isActive,
          roles: roles,
          serviceIds: serviceIds,
          schedule: schedule,
        );

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    // Procesamos el horario si existe
    Map<String, Map<String, String>>? scheduleMap;
    if (json['schedule'] != null) {
      scheduleMap = {};
      (json['schedule'] as Map<String, dynamic>).forEach((key, value) {
        if (value is Map) {
          scheduleMap![key] = {
            'start': value['start']?.toString() ?? '',
            'end': value['end']?.toString() ?? '',
          };
        }
      });
    }

    // Procesar roles
    final rolesList = <RoleEntity>[];
    if (json['roles'] != null) {
      rolesList.addAll((json['roles'] as List).map((roleJson) => RoleEntity(
            id: roleJson['id']?.toString() ?? '',
            name: roleJson['name']?.toString() ?? '',
            image: roleJson['image']?.toString(),
            route: roleJson['route']?.toString(),
          )));
    }

    // Procesar serviceIds
    List<String>? serviceIds;
    if (json['serviceIds'] != null) {
      serviceIds = List<String>.from(json['serviceIds']);
    }

    return EmployeeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lastname: json['lastname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      image: json['image']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
      roles: rolesList,
      serviceIds: serviceIds,
      schedule: scheduleMap,
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'id': id,
      'name': name,
      'lastname': lastname,
      'email': email,
      'phone': phone,
      'image': image,
      'isActive': isActive,
      'roles': roles
          .map((role) => {
                'id': role.id,
                'name': role.name,
                'image': role.image,
                'route': role.route,
              })
          .toList(),
      'serviceIds': serviceIds,
      'schedule': schedule,
    };

    // Eliminamos valores nulos
    data.removeWhere((key, value) => value == null);
    return data;
  }

  // Para crear un nuevo empleado (sin ID)
  Map<String, dynamic> toCreateJson({String? password}) {
    final data = {
      'name': name,
      'lastname': lastname,
      'email': email,
      'phone': phone,
      'serviceIds': serviceIds,
      'schedule': schedule,
    };

    if (password != null) {
      data['password'] = password;
    }

    // Eliminamos valores nulos
    data.removeWhere((key, value) => value == null);
    return data;
  }

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? image,
    bool? isActive,
    List<RoleEntity>? roles,
    List<String>? serviceIds,
    Map<String, Map<String, String>>? schedule,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      isActive: isActive ?? this.isActive,
      roles: roles ?? this.roles,
      serviceIds: serviceIds ?? this.serviceIds,
      schedule: schedule ?? this.schedule,
    );
  }
}
