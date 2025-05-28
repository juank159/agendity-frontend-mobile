import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/role_entity.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';

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
    Map<String, ServiceAssignment>? serviceAssignments,
    Map<String, Map<String, String>>? schedule,

    // 🆕 NUEVOS PARÁMETROS para Soft Delete
    bool isDeleted = false,
    DateTime? deletedAt,
    String? deletionReason,
    String? deletedBy,
  }) : super(
          id: id,
          name: name,
          lastname: lastname,
          email: email,
          phone: phone,
          image: image,
          isActive: isActive,
          roles: roles,
          serviceAssignments: serviceAssignments,
          schedule: schedule,

          // 🆕 NUEVOS CAMPOS
          isDeleted: isDeleted,
          deletedAt: deletedAt,
          deletionReason: deletionReason,
          deletedBy: deletedBy,
        );

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    // Procesamos el horario si existe (tu lógica existente)
    Map<String, Map<String, String>>? scheduleMap;

    // Verificar si hay un campo 'schedule' directo en el JSON
    if (json['schedule'] != null && json['schedule'] is Map) {
      print('Encontrado schedule en formato de objeto');
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
    // Si no hay schedule, buscar en schedules (array de horarios)
    else if (json['schedules'] != null &&
        json['schedules'] is List &&
        (json['schedules'] as List).isNotEmpty) {
      print('Encontrado schedule en formato de array: ${json['schedules']}');
      scheduleMap = {};
      final dayMap = {
        1: 'monday',
        2: 'tuesday',
        3: 'wednesday',
        4: 'thursday',
        5: 'friday',
        6: 'saturday',
        7: 'sunday'
      };

      for (var scheduleItem in (json['schedules'] as List)) {
        final dayNum = scheduleItem['day_of_week'] is int
            ? scheduleItem['day_of_week'] as int
            : int.tryParse(scheduleItem['day_of_week']?.toString() ?? '') ?? 0;

        final day = dayMap[dayNum];
        if (day != null) {
          scheduleMap[day] = {
            'start': scheduleItem['start_time']?.toString() ?? '',
            'end': scheduleItem['end_time']?.toString() ?? '',
          };
        }
      }
    } else {
      print('No se encontró información de horario en el JSON');
    }

    // Procesar roles (tu lógica existente)
    final rolesList = <RoleEntity>[];
    if (json['roles'] != null) {
      rolesList.addAll((json['roles'] as List).map((roleJson) => RoleEntity(
            id: roleJson['id']?.toString() ?? '',
            name: roleJson['name']?.toString() ?? '',
            image: roleJson['image']?.toString(),
            route: roleJson['route']?.toString(),
          )));
    }

    // Procesar asignaciones de servicios (tu lógica existente)
    Map<String, ServiceAssignment>? serviceAssignments;
    if (json['services'] != null) {
      serviceAssignments = {};
      (json['services'] as List).forEach((serviceJson) {
        final serviceId = serviceJson['serviceId']?.toString() ??
            serviceJson['id']?.toString() ??
            '';
        if (serviceId.isNotEmpty) {
          serviceAssignments![serviceId] = ServiceAssignment(
            serviceId: serviceId,
            commissionPercentage: double.tryParse(
                    serviceJson['commissionPercentage']?.toString() ?? '0') ??
                0,
            customPrice:
                double.tryParse(serviceJson['customPrice']?.toString() ?? ''),
          );
        }
      });
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
      serviceAssignments: serviceAssignments,
      schedule: scheduleMap,

      // 🆕 NUEVOS CAMPOS de Soft Delete
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'].toString())
          : null,
      deletionReason: json['deletionReason']?.toString(),
      deletedBy: json['deletedBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
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

      // 🆕 NUEVOS CAMPOS
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletionReason': deletionReason,
      'deletedBy': deletedBy,
    };

    // Añadir schedule como dynamic (tu lógica existente)
    if (schedule != null) {
      data['schedule'] = schedule as dynamic;
    }

    // Convertir serviceAssignments a formato esperado por la API (tu lógica existente)
    if (serviceAssignments != null && serviceAssignments!.isNotEmpty) {
      List<Map<String, dynamic>> servicesArray = [];
      serviceAssignments!.forEach((serviceId, assignment) {
        servicesArray.add({
          'serviceId': serviceId,
          'commissionPercentage': assignment.commissionPercentage,
          if (assignment.customPrice != null)
            'customPrice': assignment.customPrice,
        });
      });
      data['services'] = servicesArray as dynamic;
    }

    // Eliminamos valores nulos
    data.removeWhere((key, _) => data[key] == null);
    return data;
  }

  // Para crear un nuevo empleado (sin ID) - tu lógica existente
  Map<String, dynamic> toCreateJson({String? password}) {
    final Map<String, dynamic> data = {
      'name': name,
      'lastname': lastname,
      'email': email,
      'phone': phone,
    };

    // Incluir el horario si existe y no está vacío
    if (schedule != null && schedule!.isNotEmpty) {
      print('Incluyendo horario en la petición: $schedule');
      data['schedule'] = schedule as dynamic;
    } else {
      print('No hay horario para incluir en la petición');
    }

    // Convertir serviceAssignments a formato esperado por la API
    if (serviceAssignments != null && serviceAssignments!.isNotEmpty) {
      List<Map<String, dynamic>> servicesArray = [];
      serviceAssignments!.forEach((serviceId, assignment) {
        servicesArray.add({
          'serviceId': serviceId,
          'commissionPercentage': assignment.commissionPercentage,
          if (assignment.customPrice != null)
            'customPrice': assignment.customPrice,
        });
      });
      data['services'] = servicesArray as dynamic;
    }

    if (password != null && password.isNotEmpty) {
      data['password'] = password;
    }

    // Eliminamos valores nulos
    data.removeWhere((key, _) => data[key] == null);
    return data;
  }

  // 🆕 NUEVO: Método copyWith para actualizaciones
  EmployeeModel copyWith({
    String? id,
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? image,
    bool? isActive,
    List<RoleEntity>? roles,
    Map<String, ServiceAssignment>? serviceAssignments,
    Map<String, Map<String, String>>? schedule,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletionReason,
    String? deletedBy,
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
      serviceAssignments: serviceAssignments ?? this.serviceAssignments,
      schedule: schedule ?? this.schedule,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletionReason: deletionReason ?? this.deletionReason,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }
}
