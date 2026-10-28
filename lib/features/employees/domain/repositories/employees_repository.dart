import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/employee_input.dart';
import 'package:login_signup/features/employees/domain/entities/employee_restoration.dart';

/// Profesionales del negocio. Todas las rutas son solo del Owner: un Employee
/// recibe `ForbiddenFailure`. Un profesional de otro negocio, inexistente o
/// (salvo en [restoreEmployee]) dado de baja → `NotFoundFailure`.
abstract class EmployeesRepository {
  /// El Owner y sus empleados sin baja, activos o no (`GET /auth/employees`).
  Future<Either<Failure, List<EmployeeEntity>>> getEmployees();

  /// Empleados dados de baja (`GET /auth/employees/deleted`).
  Future<Either<Failure, List<EmployeeEntity>>> getDeletedEmployees();

  Future<Either<Failure, EmployeeEntity>> getEmployeeById(String id);

  /// Alta (`POST /auth/register/employee`). El empleado nace **inactivo y sin
  /// verificar** (2.16) y la respuesta no trae token (2.12) ni servicios.
  /// Email o teléfono repetido → `DuplicateEmailFailure`/`DuplicatePhoneFailure`.
  Future<Either<Failure, EmployeeEntity>> createEmployee(EmployeeInput input);

  /// Edición (`PATCH /auth/employee/:id`). Mismos failures que el alta.
  Future<Either<Failure, EmployeeEntity>> updateEmployee(
      String id, EmployeeInput input);

  /// Activar o desactivar. Activar sin el email verificado →
  /// `EmployeeEmailNotVerifiedFailure`.
  Future<Either<Failure, Unit>> setEmployeeActive(String id, bool isActive);

  /// Baja (soft-delete): queda inactivo y se puede restaurar.
  Future<Either<Failure, Unit>> deleteEmployee(String id, {String? reason});

  /// Restaura una baja; queda inactivo si no ha verificado el email.
  /// Uno que no está dado de baja → `NotFoundFailure`.
  Future<Either<Failure, EmployeeRestoration>> restoreEmployee(String id);

  /// Envía un código de verificación al email (`POST /auth/verify/request-code`).
  Future<Either<Failure, Unit>> requestVerificationCode(String email);

  /// Verifica el email con el código y **activa** al empleado
  /// (`POST /auth/verify/employee-email`). Código incorrecto, vencido o
  /// agotado → `InvalidVerificationCodeFailure` (core).
  Future<Either<Failure, Unit>> verifyEmployeeEmail({
    required String employeeId,
    required String code,
  });
}
