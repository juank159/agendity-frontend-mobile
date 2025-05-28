import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class ToggleEmployeeStatusUseCase {
  final EmployeesRepository repository;

  ToggleEmployeeStatusUseCase(this.repository);

  Future<EmployeeEntity> call(String id, bool isActive) {
    return repository.toggleEmployeeStatus(id, isActive);
  }
}
