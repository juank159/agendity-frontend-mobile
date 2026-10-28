import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/features/employees/domain/usecases/employee_rules.dart';

class VerifyEmployeeEmailParams {
  final String employeeId;
  final String code;

  const VerifyEmployeeEmailParams({
    required this.employeeId,
    required this.code,
  });
}

/// Verifica el email del empleado con el código de 6 dígitos. El backend lo
/// **activa** en el mismo paso (no hace falta activarlo después). Código
/// incorrecto, vencido o agotado → `InvalidVerificationCodeFailure` (core).
class VerifyEmployeeEmailUseCase
    extends UseCase<Unit, VerifyEmployeeEmailParams> {
  final EmployeesRepository repository;

  VerifyEmployeeEmailUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(VerifyEmployeeEmailParams params) async {
    if (params.employeeId.trim().isEmpty) {
      return const Left(
          InvalidEmployeeDataFailure(message: 'Falta el profesional'));
    }
    if (!EmployeeRules.isValidCode(params.code)) {
      return const Left(
          InvalidEmployeeDataFailure(message: EmployeeRules.codeInvalid));
    }
    return repository.verifyEmployeeEmail(
        employeeId: params.employeeId.trim(), code: params.code.trim());
  }
}
