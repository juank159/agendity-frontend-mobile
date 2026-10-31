import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/features/services/data/datasources/catalog_local_datasource.dart';
import 'package:login_signup/features/services/data/models/service_model.dart';
import 'package:login_signup/features/services/data/sync/catalog_sync.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/failures/services_failures.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';

/// Servicios sin conexión (10.02b, D-18): se leen de la base local y las
/// altas, ediciones y borrados van a local + bandeja (`service.*`). El nombre
/// repetido se avisa con lo local; el servidor sigue decidiendo.
class ServicesRepositoryImpl implements ServicesRepository {
  final OfflineStore _store;
  final CatalogLocalDataSource _local;

  ServicesRepositoryImpl(this._store,
      {CatalogLocalDataSource local = const CatalogLocalDataSource()})
      : _local = local;

  static const _entity = 'services';

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices() =>
      safeCall(() async => _local.services(await _store.database()));

  @override
  Future<Either<Failure, List<ServiceEntity>>> getAllServices() => safeCall(
      () async =>
          _local.services(await _store.database(), includeInactive: true));

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServicesOfferedBy(
          String professionalId) =>
      safeCall(() async =>
          _local.offeredBy(await _store.database(), professionalId));

  @override
  Future<Either<Failure, ServiceEntity>> createService(ServiceEntity service) =>
      OfflineStore.guard(() async {
        final db = await _store.database();
        if (await _local.nameTaken(db, _entity, service.name)) {
          return const Left(DuplicateServiceNameFailure());
        }
        final id = _store.newId();
        await _store.write((db, sink) async {
          final entry = await sink.add(
              type: CatalogSync.serviceCreate,
              entity: _entity,
              entityId: id,
              payload: ServiceModel.fromEntity(service).toJson());
          await CatalogSync.apply(db, entry, extra: _created());
        });
        return Right((await _local.service(db, id))!);
      });

  @override
  Future<Either<Failure, ServiceEntity>> updateService(ServiceEntity service) =>
      OfflineStore.guard(() async {
        final db = await _store.database();
        final id = service.id;
        final current = id == null ? null : await _local.service(db, id);
        if (current == null) return const Left(NotFoundFailure());
        if (await _local.nameTaken(db, _entity, service.name, exceptId: id)) {
          return const Left(DuplicateServiceNameFailure());
        }
        final changes = _diff(ServiceModel.fromEntity(current).toUpdateJson(),
            ServiceModel.fromEntity(service).toUpdateJson());
        if (changes.isEmpty) return Right(current);
        await _store.write((db, sink) async {
          final entry = await sink.add(
              type: CatalogSync.serviceUpdate,
              entity: _entity,
              entityId: id,
              payload: changes);
          await CatalogSync.apply(db, entry,
              extra: {'updatedAt': _store.nowIso()});
        });
        return Right((await _local.service(db, id!))!);
      });

  @override
  Future<Either<Failure, Unit>> deleteService(String id) =>
      OfflineStore.guard(() async {
        final db = await _store.database();
        if (await _local.service(db, id) == null) {
          return const Left(NotFoundFailure());
        }
        await _store.write((db, sink) async {
          final entry = await sink.add(
              type: CatalogSync.serviceDelete, entity: _entity, entityId: id);
          await CatalogSync.apply(db, entry);
        });
        return const Right(unit);
      });

  Map<String, dynamic> _created() =>
      {'createdAt': _store.nowIso(), 'updatedAt': _store.nowIso()};

  /// Solo los campos que cambian (en el servidor gana la última escritura
  /// por campo).
  static Map<String, dynamic> _diff(
          Map<String, dynamic> before, Map<String, dynamic> after) =>
      {
        for (final entry in after.entries)
          if (jsonEncode(before[entry.key]) != jsonEncode(entry.value))
            entry.key: entry.value,
      };
}
