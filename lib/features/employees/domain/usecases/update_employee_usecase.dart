// lib/features/employees/domain/usecases/update_employee_usecase.dart

import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
// MODIFICAR: Cambia esta importación, quita el alias 'as sa'
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class UpdateEmployeeUseCase {
  final EmployeesRepository repository;

  UpdateEmployeeUseCase(this.repository);

  // MODIFICAR: Cambia el tipo de parámetro, quita 'sa.'
  Future<EmployeeEntity> call(
    String id,
    EmployeeEntity employee, {
    String? password,
    Map<String, ServiceAssignment>? serviceAssignments,
  }) {
    print(
        '⭐ UseCase: Actualizando empleado con ${serviceAssignments?.length ?? 0} servicios');
    return repository.updateEmployee(
      id,
      employee,
      password: password,
      serviceAssignments: serviceAssignments,
    );
  }
}
