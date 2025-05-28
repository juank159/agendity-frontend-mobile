// // lib/features/employees/domain/entities/employee_entity.dart
// // ARCHIVO COMPLETO - Asegúrate de que se vea exactamente así

// import 'package:login_signup/features/employees/domain/entities/role_entity.dart';
// import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';

// class EmployeeEntity {
//   final String id;
//   final String name;
//   final String lastname;
//   final String email;
//   final String phone;
//   final String? image;
//   final bool isActive;
//   final List<RoleEntity> roles;
//   final Map<String, ServiceAssignment>? serviceAssignments;
//   final Map<String, Map<String, String>>? schedule;

//   EmployeeEntity({
//     required this.id,
//     required this.name,
//     required this.lastname,
//     required this.email,
//     required this.phone,
//     this.image,
//     required this.isActive,
//     required this.roles,
//     this.serviceAssignments,
//     this.schedule,
//   });

//   // Getter para obtener el nombre completo
//   String get fullName => '$name $lastname'.trim();

//   // Getter para compatibilidad con el código existente
//   List<String>? get serviceIds => serviceAssignments?.keys.toList();
// }

// // NO DEBE HABER NINGUNA OTRA CLASE AQUÍ

// lib/features/employees/domain/entities/employee_entity.dart
// ARCHIVO COMPLETO - Asegúrate de que se vea exactamente así

import 'package:flutter/material.dart';
import 'package:login_signup/features/employees/domain/entities/role_entity.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';

class EmployeeEntity {
  final String id;
  final String name;
  final String lastname;
  final String email;
  final String phone;
  final String? image;
  final bool isActive;
  final List<RoleEntity> roles;
  final Map<String, ServiceAssignment>? serviceAssignments;
  final Map<String, Map<String, String>>? schedule;

  // 🆕 NUEVOS CAMPOS para Soft Delete
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletionReason;
  final String? deletedBy;

  EmployeeEntity({
    required this.id,
    required this.name,
    required this.lastname,
    required this.email,
    required this.phone,
    this.image,
    required this.isActive,
    required this.roles,
    this.serviceAssignments,
    this.schedule,

    // 🆕 NUEVOS PARÁMETROS con valores por defecto
    this.isDeleted = false,
    this.deletedAt,
    this.deletionReason,
    this.deletedBy,
  });

  // Getter para obtener el nombre completo
  String get fullName => '$name $lastname'.trim();

  // Getter para compatibilidad con el código existente
  List<String>? get serviceIds => serviceAssignments?.keys.toList();

  // 🆕 NUEVOS: Getters para manejar estados
  bool get canLogin => isActive && !isDeleted;
  bool get canBeScheduled => isActive && !isDeleted;
  bool get wasDeleted => isDeleted || deletedAt != null;

  String get displayStatus {
    if (isDeleted) return 'Eliminado';
    if (!isActive) return 'Inactivo';
    return 'Activo';
  }

  Color get statusColor {
    if (isDeleted) return Colors.red;
    if (!isActive) return Colors.orange;
    return Colors.green;
  }

  IconData get statusIcon {
    if (isDeleted) return Icons.delete_forever;
    if (!isActive) return Icons.pause_circle;
    return Icons.check_circle;
  }
}

// NO DEBE HABER NINGUNA OTRA CLASE AQUÍ
