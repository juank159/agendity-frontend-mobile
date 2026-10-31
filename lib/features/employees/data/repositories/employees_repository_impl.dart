import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/features/employees/data/datasources/employees_local_datasource.dart';
import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/data/models/employee_input_model.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/employee_input.dart';
import 'package:login_signup/features/employees/domain/entities/employee_restoration.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

/// Profesionales (10.02b): **se leen de la base local** (también sin
/// conexión, y la empleada ve a sus compañeros para la agenda). Las altas,
/// ediciones, activación, bajas y verificación siguen siendo con conexión
/// (no hay mutaciones de empleados en `/sync/push`); después de cada una se
/// sincroniza para que lo local quede al día.
class EmployeesRepositoryImpl implements EmployeesRepository {
  final EmployeesRemoteDataSource _remote;
  final OfflineStore _store;
  final EmployeesLocalDataSource _local;

  /// Sincronización tras un cambio con conexión (`SyncEngine.syncNow`).
  final Future<void> Function() _refresh;

  EmployeesRepositoryImpl(
    this._remote, {
    required OfflineStore store,
    required Future<void> Function() refresh,
    EmployeesLocalDataSource local = const EmployeesLocalDataSource(),
  })  : _store = store,
        _refresh = refresh,
        _local = local;

  @override
  Future<Either<Failure, List<EmployeeEntity>>> getEmployees() =>
      safeCall(() async => _local.employees(await _store.database()));

  @override
  Future<Either<Failure, List<EmployeeEntity>>> getDeletedEmployees() =>
      safeCall(() async =>
          _local.employees(await _store.database(), deleted: true));

  @override
  Future<Either<Failure, EmployeeEntity>> getEmployeeById(String id) async {
    final result = await safeCall<EmployeeEntity?>(
        () async => _local.employee(await _store.database(), id));
    return result.fold(Left.new,
        (e) => e == null ? const Left(NotFoundFailure()) : Right(e));
  }

  /// Con conexión; si sale bien, sincroniza (sin esperar errores de red).
  Future<Either<Failure, T>> _online<T>(Future<Either<Failure, T>> call) async {
    final result = await call;
    if (result.isRight()) {
      try {
        await _refresh();
      } catch (_) {
        // La próxima sincronización lo traerá.
      }
    }
    return result;
  }

  @override
  Future<Either<Failure, EmployeeEntity>> createEmployee(EmployeeInput input) =>
      _online(safeCall(
        () async =>
            (await _remote.createEmployee(EmployeeInputModel.fromEntity(input)))
                .toEntity(),
        refine: (failure) => _refineDuplicate(failure, input),
      ));

  @override
  Future<Either<Failure, EmployeeEntity>> updateEmployee(
          String id, EmployeeInput input) =>
      _online(safeCall(
        () async => (await _remote.updateEmployee(
                id, EmployeeInputModel.fromEntity(input)))
            .toEntity(),
        refine: (failure) => _refineDuplicate(failure, input),
      ));

  @override
  Future<Either<Failure, Unit>> setEmployeeActive(String id, bool isActive) =>
      _online(safeCall(
        () async {
          await _remote.setEmployeeActive(id, isActive);
          return unit;
        },
        refine: _refineStatus,
      ));

  @override
  Future<Either<Failure, Unit>> deleteEmployee(String id, {String? reason}) =>
      _online(safeCall(() async {
        await _remote.deleteEmployee(id, reason: reason);
        return unit;
      }));

  @override
  Future<Either<Failure, EmployeeRestoration>> restoreEmployee(String id) =>
      _online(safeCall(
          () async => (await _remote.restoreEmployee(id)).toEntity()));

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
      _online(safeCall(() async {
        await _remote.verifyEmployeeEmail(employeeId, code);
        return unit;
      }));

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
