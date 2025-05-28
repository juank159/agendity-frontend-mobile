import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class DeleteEmployeeUseCase {
  final EmployeesRepository repository;

  DeleteEmployeeUseCase(this.repository);

  // 🔄 MODIFICADO: Ahora acepta razón opcional
  Future<bool> call(String id, {String? reason}) async {
    try {
      print('🎯 UseCase: Iniciando eliminación de empleado $id');
      if (reason != null && reason.isNotEmpty) {
        print('🎯 UseCase: Razón: $reason');
      }

      final result = await repository.deleteEmployee(id, reason: reason);

      print('✅ UseCase: Eliminación completada');
      return result;
    } catch (e) {
      print('❌ UseCase: Error - $e');
      rethrow;
    }
  }
}
