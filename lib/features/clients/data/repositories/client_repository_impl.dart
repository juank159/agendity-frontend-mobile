import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/clients/data/models/client_model.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/client_import_result.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/features/clients/domain/entities/paginated_list.dart';
import 'package:login_signup/features/clients/domain/failures/client_failures.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';

class ClientsRepositoryImpl implements ClientsRepository {
  final ClientsRemoteDataSource _remote;

  ClientsRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedList<ClientEntity>>> getClients(
          ClientsQuery query) =>
      safeCall(() async => (await _remote.getClients(query)).toEntity());

  @override
  Future<Either<Failure, List<ClientEntity>>> getAllClients() =>
      safeCall(() async =>
          (await _remote.getAllClients()).map((m) => m.toEntity()).toList());

  @override
  Future<Either<Failure, ClientEntity>> getClientById(String id) =>
      safeCall(() async => (await _remote.getClientById(id)).toEntity());

  @override
  Future<Either<Failure, ClientEntity>> createClient(ClientEntity client) =>
      safeCall(
        () async => (await _remote.createClient(ClientModel.fromEntity(client)))
            .toEntity(),
        refine: _refineSave,
      );

  @override
  Future<Either<Failure, ClientEntity>> updateClient(ClientEntity client) =>
      safeCall(
        () async => (await _remote.updateClient(
                client.id!, ClientModel.fromEntity(client)))
            .toEntity(),
        refine: _refineSave,
      );

  @override
  Future<Either<Failure, Unit>> deleteClient(String id) => safeCall(
        () async {
          await _remote.deleteClient(id);
          return unit;
        },
        refine: _refineDelete,
      );

  @override
  Future<Either<Failure, ClientImportResult>> importClients(
          List<ClientEntity> clients) =>
      safeCall(() async => (await _remote
              .importClients(clients.map(ClientModel.fromEntity).toList()))
          .toEntity(sent: clients.length));

  @override
  Future<Either<Failure, String>> uploadImage(String filePath) =>
      safeCall(() => _remote.uploadImage(filePath));

  /// Al crear o editar, los 409 son de unicidad dentro del negocio:
  /// `DUPLICATE_PHONE` (índice único, alta simultánea) o `CONFLICT` (la
  /// comprobación previa del backend; su mensaje dice si es el teléfono o el
  /// email).
  static Failure _refineSave(Failure failure) => switch (failure.code) {
        ApiErrorCode.duplicatePhone => DuplicateClientPhoneFailure(
            statusCode: failure.statusCode, details: failure.details),
        ApiErrorCode.duplicateEmail ||
        ApiErrorCode.conflict =>
          DuplicateClientFailure(
              message: failure.message,
              code: failure.code,
              statusCode: failure.statusCode,
              details: failure.details),
        _ => failure,
      };

  /// Al borrar, el único 409 es la clave foránea de citas o reseñas.
  static Failure _refineDelete(Failure failure) =>
      failure.code == ApiErrorCode.conflict
          ? ClientHasHistoryFailure(
              code: failure.code,
              statusCode: failure.statusCode,
              details: failure.details)
          : failure;
}
