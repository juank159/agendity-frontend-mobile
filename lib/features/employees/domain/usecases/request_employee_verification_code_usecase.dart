import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/features/employees/domain/usecases/employee_rules.dart';

/// Envía (o reenvía) el código de verificación al email del empleado. El
/// código vale 10 minutos; pedir uno nuevo invalida el anterior. Demasiadas
/// peticiones → `TooManyRequestsFailure`.
class RequestEmployeeVerificationCodeUseCase extends UseCase<Unit, String> {
  final EmployeesRepository repository;

  RequestEmployeeVerificationCodeUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String params) async {
    final email = params.trim();
    if (!EmployeeRules.isValidEmail(email)) {
      return const Left(
          InvalidEmployeeDataFailure(message: EmployeeRules.emailInvalid));
    }
    return repository.requestVerificationCode(email);
  }
}
