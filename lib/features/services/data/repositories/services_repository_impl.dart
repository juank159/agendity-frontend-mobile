import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/features/services/data/datasources/services_remote_datasource.dart';
import 'package:login_signup/features/services/data/models/service_model.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/failures/services_failures.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource _remote;

  ServicesRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices() =>
      safeCall(() async =>
          (await _remote.getServices()).map((m) => m.toEntity()).toList());

  @override
  Future<Either<Failure, ServiceEntity>> createService(ServiceEntity service) =>
      safeCall(
        () async =>
            (await _remote.createService(ServiceModel.fromEntity(service)))
                .toEntity(),
        refine: _refineSave,
      );

  @override
  Future<Either<Failure, ServiceEntity>> updateService(ServiceEntity service) =>
      safeCall(
        () async => (await _remote.updateService(
                service.id!, ServiceModel.fromEntity(service)))
            .toEntity(),
        refine: _refineSave,
      );

  @override
  Future<Either<Failure, Unit>> deleteService(String id) => safeCall(() async {
        await _remote.deleteService(id);
        return unit;
      });

  /// Al crear o editar, el único 409 posible es el nombre repetido en el
  /// negocio (`ConflictException` del backend → `code: CONFLICT`).
  static Failure _refineSave(Failure failure) =>
      failure.code == ApiErrorCode.conflict
          ? DuplicateServiceNameFailure(
              message: failure.message,
              code: failure.code,
              statusCode: failure.statusCode,
              details: failure.details,
            )
          : failure;
}
