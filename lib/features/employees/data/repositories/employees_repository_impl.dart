import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/data/models/employee_input_model.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/employee_input.dart';
import 'package:login_signup/features/employees/domain/entities/employee_restoration.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class EmployeesRepositoryImpl implements EmployeesRepository {
  final EmployeesRemoteDataSource _remote;

  EmployeesRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<EmployeeEntity>>> getEmployees() => safeCall(
      () async => (await _remote.getEmployees()).map((m) => m.toEntity()).toList());

  @override
  Future<Either<Failure, List<EmployeeEntity>>> getDeletedEmployees() =>
      safeCall(() async => (await _remote.getDeletedEmployees())
          .map((m) => m.toEntity())
          .toList());

  @override
  Future<Either<Failure, EmployeeEntity>> getEmployeeById(String id) =>
      safeCall(() async => (await _remote.getEmployeeById(id)).toEntity());

  @override
  Future<Either<Failure, EmployeeEntity>> createEmployee(EmployeeInput input) =>
      safeCall(
        () async =>
            (await _remote.createEmployee(EmployeeInputModel.fromEntity(input)))
                .toEntity(),
        refine: (failure) => _refineDuplicate(failure, input),
      );

  @override
  Future<Either<Failure, EmployeeEntity>> updateEmployee(
          String id, EmployeeInput input) =>
      safeCall(
        () async => (await _remote.updateEmployee(
                id, EmployeeInputModel.fromEntity(input)))
            .toEntity(),
        refine: (failure) => _refineDuplicate(failure, input),
      );

  @override
  Future<Either<Failure, Unit>> setEmployeeActive(String id, bool isActive) =>
      safeCall(
        () async {
          await _remote.setEmployeeActive(id, isActive);
          return unit;
        },
        refine: _refineStatus,
      );

  @override
  Future<Either<Failure, Unit>> deleteEmployee(String id, {String? reason}) =>
      safeCall(() async {
        await _remote.deleteEmployee(id, reason: reason);
        return unit;
      });

  @override
  Future<Either<Failure, EmployeeRestoration>> restoreEmployee(String id) =>
      safeCall(() async => (await _remote.restoreEmployee(id)).toEntity());

  @override
  Future<Either<Failure, Unit>> requestVerificationCode(String email) =>
      safeCall(() async {
        await _remote.requestVerificationCode(email);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> verifyEmployeeEmail({
    required String employeeId,
    required String code,
  }) =>
      safeCall(() async {
        await _remote.verifyEmployeeEmail(employeeId, code);
        return unit;
      });

  /// El `ErrorMapper` ya da `DuplicateEmail/PhoneFailure` por `code`; aquí
  /// se completa el valor repetido con el que se envió.
  static Failure _refineDuplicate(Failure failure, EmployeeInput input) =>
      switch (failure) {
        DuplicateEmailFailure() => DuplicateEmailFailure(
            email: input.email,
            message: failure.message,
            statusCode: failure.statusCode,
            details: failure.details),
        DuplicatePhoneFailure() => DuplicatePhoneFailure(
            phone: input.phone,
            message: failure.message,
            statusCode: failure.statusCode,
            details: failure.details),
        _ => failure,
      };

  static Failure _refineStatus(Failure failure) =>
      failure.code == ApiErrorCode.emailNotVerified
          ? EmployeeEmailNotVerifiedFailure(
              message: failure.message,
              statusCode: failure.statusCode,
              details: failure.details)
          : failure;
}
