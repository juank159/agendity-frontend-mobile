import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/employee_input.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/features/employees/domain/usecases/employee_rules.dart';

class UpdateEmployeeParams {
  final String id;
  final EmployeeInput input;

  const UpdateEmployeeParams({required this.id, required this.input});
}

/// Edita un profesional. Mismas reglas que el alta, pero la contraseña es
/// opcional (vacía = no se cambia). Servicios y horario se sustituyen.
class UpdateEmployeeUseCase
    extends UseCase<EmployeeEntity, UpdateEmployeeParams> {
  static const missingId = 'Falta el profesional a editar';

  final EmployeesRepository repository;

  UpdateEmployeeUseCase(this.repository);

  @override
  Future<Either<Failure, EmployeeEntity>> call(
      UpdateEmployeeParams params) async {
    final input = EmployeeRules.normalize(params.input);
    final problems = [
      if (params.id.trim().isEmpty) missingId,
      ...EmployeeRules.check(input, requirePassword: false),
    ];
    if (problems.isNotEmpty) {
      return Left(InvalidEmployeeDataFailure.of(problems));
    }
    return repository.updateEmployee(params.id.trim(), input);
  }
}
