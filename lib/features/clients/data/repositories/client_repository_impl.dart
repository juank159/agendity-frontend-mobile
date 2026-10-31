import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/features/clients/data/datasources/clients_local_datasource.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/clients/data/models/client_model.dart';
import 'package:login_signup/features/clients/data/sync/clients_sync_handler.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/client_import_result.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/features/clients/domain/entities/paginated_list.dart';
import 'package:login_signup/features/clients/domain/failures/client_failures.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';

/// Clientes sin conexión (10.02, D-18): se leen **siempre** de la base local
/// y cada alta, edición o borrado se guarda en local y en la bandeja de
/// salida (`client.*`) en una sola transacción; `SyncEngine` los sube. Las
/// reglas de unicidad (teléfono y email en el negocio) se comprueban contra
/// lo local para avisar al momento; el servidor sigue decidiendo (fusión de
/// teléfonos repetidos, `merged`). Solo la foto necesita conexión.
class ClientsRepositoryImpl implements ClientsRepository {
  final ClientsRemoteDataSource _remote;
  final ClientsLocalDataSource _local;
  final OfflineStore _store;

  ClientsRepositoryImpl({
    required ClientsRemoteDataSource remote,
    required OfflineStore store,
    ClientsLocalDataSource local = const ClientsLocalDataSource(),
  })  : _remote = remote,
        _store = store,
        _local = local;

  static const _entity = ClientsSyncHandler.entityName;

  @override
  Future<Either<Failure, PaginatedList<ClientEntity>>> getClients(
          ClientsQuery query) =>
      safeCall(() async => _local.page(await _store.database(), query));

  @override
  Future<Either<Failure, ClientEntity>> getClientById(String id) async {
    final result = await safeCall<ClientEntity?>(
        () async => _local.byId(await _store.database(), id));
    return result.fold(Left.new,
        (client) => client == null ? const Left(NotFoundFailure()) : Right(client));
  }

  @override
  Future<Either<Failure, ClientEntity>> createClient(ClientEntity client) =>
      _guarded(() async {
        final db = await _store.database();
        final duplicate = await _duplicate(db, client);
        if (duplicate != null) return Left(duplicate);
        final id = _store.newId();
        await _store.write((db, sink) async {
          final payload = ClientModel.fromEntity(client).toJson();
          await _local.upsertFields(db, id, {
            ...payload,
            'isActive': true,
            'isFromDevice': false,
            'created_at': _nowIso(),
            'updated_at': _nowIso(),
          });
          await sink.add(
              type: ClientsSyncHandler.create,
              entity: _entity,
              entityId: id,
              payload: payload);
        });
        return Right((await _local.byId(db, id))!);
      });

  @override
  Future<Either<Failure, ClientEntity>> updateClient(ClientEntity client) =>
      _guarded(() async {
        final id = client.id;
        final db = await _store.database();
        final current = id == null ? null : await _local.byId(db, id);
        if (current == null) return const Left(NotFoundFailure());
        final duplicate = await _duplicate(db, client, exceptId: current.id);
        if (duplicate != null) return Left(duplicate);

        // Solo lo que cambia: en el servidor gana la última escritura por
        // campo, así no se pisa lo que otro dispositivo cambió.
        final before = ClientModel.fromEntity(current).toJson();
        final after = ClientModel.fromEntity(client).toJson();
        final changes = {
          for (final entry in after.entries)
            if (jsonEncode(before[entry.key]) != jsonEncode(entry.value))
              entry.key: entry.value,
        };
        if (changes.isEmpty) return Right(current);

        await _store.write((db, sink) async {
          await _local.upsertFields(
              db, current.id!, {...changes, 'updated_at': _nowIso()});
          await sink.add(
              type: ClientsSyncHandler.update,
              entity: _entity,
              entityId: current.id,
              payload: changes);
        });
        return Right((await _local.byId(db, current.id!))!);
      });

  /// Borra en local al momento. Si el servidor no lo permite (citas o
  /// reseñas, o un Employee), la operación queda rechazada en la bandeja y el
  /// cliente vuelve a aparecer.
  @override
  Future<Either<Failure, Unit>> deleteClient(String id) => _guarded(() async {
        final db = await _store.database();
        final current = await _local.byId(db, id);
        if (current == null) return const Left(NotFoundFailure());
        await _store.write((db, sink) async {
          await _local.delete(db, current.id!);
          await sink.add(
              type: ClientsSyncHandler.remove,
              entity: _entity,
              entityId: current.id);
        });
        return const Right(unit);
      });

  /// Cada contacto es un `client.create` en la bandeja. Un teléfono ya
  /// registrado (en local o repetido en la lista) se rechaza aquí; si otro
  /// dispositivo lo creó mientras tanto, el servidor lo fusiona.
  @override
  Future<Either<Failure, ClientImportResult>> importClients(
          List<ClientEntity> clients) =>
      _guarded(() async {
        final db = await _store.database();
        final rejected = <ClientImportRejection>[];
        final accepted = <ClientEntity>[];
        final phones = <String>{};
        for (final client in clients) {
          if (!phones.add(client.phone) ||
              await _local.phoneTaken(db, client.phone)) {
            rejected.add(ClientImportRejection(
                name: client.fullName,
                phone: client.phone,
                reason: _phoneTaken(client.phone)));
          } else {
            accepted.add(client);
          }
        }
        await _store.write((db, sink) async {
          for (final client in accepted) {
            final id = _store.newId();
            final payload = ClientModel.fromEntity(client).toJson();
            await _local.upsertFields(db, id, {
              ...payload,
              'isActive': true,
              'isFromDevice': false,
              'created_at': _nowIso(),
              'updated_at': _nowIso(),
            });
            await sink.add(
                type: ClientsSyncHandler.create,
                entity: _entity,
                entityId: id,
                payload: payload);
          }
        });
        return Right(ClientImportResult(
            requested: clients.length,
            imported: accepted.length,
            rejected: rejected));
      });

  /// Solo con conexión. Un archivo que ya no existe es un error del usuario
  /// (elegir otra foto), no del servidor.
  @override
  Future<Either<Failure, String>> uploadImage(String filePath) async {
    if (!File(filePath).existsSync()) {
      return const Left(InvalidClientDataFailure(
          message: ClientsRemoteDataSourceImpl.unreadableImage));
    }
    return safeCall(() => _remote.uploadImage(filePath));
  }

  /// Mismos textos que el backend (2.30).
  Future<Failure?> _duplicate(AppDatabase db, ClientEntity client,
      {String? exceptId}) async {
    if (await _local.phoneTaken(db, client.phone, exceptId: exceptId)) {
      return DuplicateClientPhoneFailure(message: _phoneTaken(client.phone));
    }
    final email = client.email;
    if (email != null &&
        email.isNotEmpty &&
        await _local.emailTaken(db, email, exceptId: exceptId)) {
      return DuplicateClientFailure(
          message: 'Ya existe un cliente con el email: $email',
          code: ApiErrorCode.duplicateEmail);
    }
    return null;
  }

  static String _phoneTaken(String phone) =>
      'Ya existe un cliente con el teléfono: $phone';

  String _nowIso() => _store.now().toUtc().toIso8601String();

  /// Errores locales (sin sesión, base dañada) como failure, sin lanzar.
  static Future<Either<Failure, T>> _guarded<T>(
      Future<Either<Failure, T>> Function() body) async {
    final result = await safeCall(body);
    return result.fold(Left.new, (inner) => inner);
  }
}
