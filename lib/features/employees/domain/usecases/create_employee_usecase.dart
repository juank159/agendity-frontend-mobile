import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class CreateEmployeeUseCase {
  final EmployeesRepository repository;

  CreateEmployeeUseCase(this.repository);

  Future<EmployeeEntity> call(EmployeeEntity employee, String password) async {
    try {
      return await repository.createEmployee(employee, password);
    } catch (e) {
      print('Error en UseCase: $e');

      // Simplemente reenviar el error sin transformarlo
      rethrow;
    }
  }
}
