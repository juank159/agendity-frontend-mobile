import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/employee_input.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/features/employees/domain/usecases/employee_rules.dart';

/// Crea un empleado con contraseña, servicios y horario. Nace **inactivo y
/// sin verificar** (2.16): el siguiente paso es verificar su email
/// (`RequestEmployeeVerificationCodeUseCase` + `VerifyEmployeeEmailUseCase`).
/// Datos fuera de las reglas → `InvalidEmployeeDataFailure` sin llamar al
/// backend; email o teléfono repetido → `DuplicateEmailFailure`/`DuplicatePhoneFailure`.
class CreateEmployeeUseCase extends UseCase<EmployeeEntity, EmployeeInput> {
  final EmployeesRepository repository;

  CreateEmployeeUseCase(this.repository);

  @override
  Future<Either<Failure, EmployeeEntity>> call(EmployeeInput params) async {
    final input = EmployeeRules.normalize(params);
    final problems = EmployeeRules.check(input, requirePassword: true);
    if (problems.isNotEmpty) {
      return Left(InvalidEmployeeDataFailure.of(problems));
    }
    return repository.createEmployee(input);
  }
}
