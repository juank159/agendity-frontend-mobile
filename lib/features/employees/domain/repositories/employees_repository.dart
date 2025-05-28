// // lib/features/employees/domain/repositories/employees_repository.dart

// import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
// import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';

// abstract class EmployeesRepository {
//   Future<List<EmployeeEntity>> getEmployees();
//   Future<EmployeeEntity> getEmployeeById(String id);
//   Future<EmployeeEntity> createEmployee(
//       EmployeeEntity employee, String password);

//   Future<EmployeeEntity> updateEmployee(
//     String id,
//     EmployeeEntity employee, {
//     String? password,
//     Map<String, ServiceAssignment>? serviceAssignments,
//   });

//   Future<bool> verifyEmployeeEmail(String employeeId, String code);

//   Future<bool> deleteEmployee(String id);
//   Future<EmployeeEntity> toggleEmployeeStatus(String id, bool isActive);
// }

// lib/features/employees/domain/repositories/employees_repository.dart

import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';

abstract class EmployeesRepository {
  // Métodos existentes
  Future<List<EmployeeEntity>> getEmployees();
  Future<EmployeeEntity> getEmployeeById(String id);
  Future<EmployeeEntity> createEmployee(
      EmployeeEntity employee, String password);
  Future<EmployeeEntity> updateEmployee(
    String id,
    EmployeeEntity employee, {
    String? password,
    Map<String, ServiceAssignment>? serviceAssignments,
  });
  Future<bool> verifyEmployeeEmail(String employeeId, String code);
  Future<EmployeeEntity> toggleEmployeeStatus(String id, bool isActive);

  // 🔄 MODIFICADO: deleteEmployee ahora acepta razón opcional
  Future<bool> deleteEmployee(String id, {String? reason});

  // 🆕 NUEVOS: Métodos para soft delete
  Future<bool> restoreEmployee(String id);
  Future<List<EmployeeEntity>> getActiveEmployees();
  Future<List<EmployeeEntity>> getDeletedEmployees();
  Future<List<EmployeeEntity>> getAllEmployees({bool includeDeleted = false});
}
