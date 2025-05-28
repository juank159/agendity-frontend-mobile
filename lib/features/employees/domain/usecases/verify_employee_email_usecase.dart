import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class VerifyEmployeeEmailUseCase {
  final EmployeesRepository repository;

  VerifyEmployeeEmailUseCase(this.repository);

  Future<bool> call({required String employeeId, required String code}) async {
    try {
      return await repository.verifyEmployeeEmail(employeeId, code);
    } catch (e) {
      print('Error en VerifyEmployeeEmailUseCase: $e');
      throw Exception('Error al verificar el email del empleado: $e');
    }
  }
}
