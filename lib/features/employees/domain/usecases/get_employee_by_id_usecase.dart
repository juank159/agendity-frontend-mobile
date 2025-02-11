import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class GetEmployeeByIdUseCase {
  final EmployeesRepository repository;

  GetEmployeeByIdUseCase(this.repository);

  Future<EmployeeEntity> call(String id) async {
    return await repository.getEmployeeById(id);
  }
}
