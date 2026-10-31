import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/network/interceptors/auth_interceptor.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_api.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/features/clients/data/datasources/clients_local_datasource.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/clients/data/repositories/client_repository_impl.dart';
import 'package:login_signup/features/clients/data/sync/clients_sync_handler.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';

import '../session/memory_token_store.dart';
import 'fake_sync_api.dart';

/// Contrato real de `/sync` con clientes (10.02a). Solo corre con un backend
/// sobre una **copia** de `agendity_demo` (escribe):
///
///   SYNC_E2E_URL=http://127.0.0.1:3995/api flutter test test/core/sync/sync_live_test.dart
void main() {
  final url = Platform.environment['SYNC_E2E_URL'];

  test('clientes: alta sin red, subida, fusión por teléfono y bajada',
      () async {
    final tokens = MemoryTokenStore();
    final dio = buildApiClient(
        baseUrl: url!, tokenStore: tokens, enableLogs: false);
    final login = await dio.post<Map<String, dynamic>>('/auth/login',
        data: {'email': 'marcela.rojas@example.com', 'password': 'Clave@2026a'},
        options: Options(extra: {AuthInterceptor.publicKey: true}));
    tokens.token = login.data!['token'] as String;

    final databases = memoryDatabases();
    final engine = SyncEngine(
      databases: databases,
      api: DioSyncApi(dio),
      handlers: [
        ClientsSyncHandler(
            const ClientsLocalDataSource(), ClientsRemoteDataSourceImpl(dio)),
      ],
    );
    final repository = ClientsRepositoryImpl(
      remote: ClientsRemoteDataSourceImpl(dio),
      store: OfflineStore(databases: databases),
    );
    final db = await databases.require();

    // Carga inicial.
    await engine.syncNow();
    expect(engine.current.lastError, isNull);
    final before =
        (await repository.getClients(const ClientsQuery(limit: 100)))
            .getOrElse(() => throw StateError('lectura'));
    expect(before.total, greaterThan(0));
    final existing = before.items.first;

    // Alta nueva y alta con un teléfono que ya existe (fusión).
    final suffix = DateTime.now().millisecondsSinceEpoch % 10000000;
    final created = (await repository.createClient(ClientEntity(
            name: 'Offline', lastname: 'Prueba', phone: '311$suffix'.padRight(10, '0'))))
        .getOrElse(() => throw StateError('alta'));
    final duplicateId = 'ffffffff-0000-7000-8000-${suffix.toString().padLeft(12, '0')}';
    await OfflineStore(databases: databases, newId: () => duplicateId)
        .write((db, sink) async {
      final payload = {'name': 'Dup', 'lastname': '', 'phone': existing.phone};
      await const ClientsLocalDataSource().upsertFields(db, duplicateId, payload);
      await sink.add(
          type: 'client.create',
          entity: 'clients',
          entityId: duplicateId,
          payload: payload);
    });
    final edited = (await repository.updateClient(
            created.copyWith(notes: 'Creado sin red')))
        .getOrElse(() => throw StateError('edición'));

    await engine.syncNow();
    expect(engine.current.lastError, isNull);
    expect(await OutboxStore.all(db), isEmpty);

    // Lo creado llegó con la forma del servidor.
    final synced = (await repository.getClientById(edited.id!))
        .getOrElse(() => throw StateError('leer'));
    expect(synced.notes, 'Creado sin red');
    expect(synced.createdAt, isNotNull);
    // El duplicado se fusionó con el existente.
    expect((await repository.getClientById(duplicateId))
            .getOrElse(() => throw StateError('alias'))
            .id,
        existing.id);

    // Borrado sube y la bajada lo confirma.
    await repository.deleteClient(created.id!);
    await engine.syncNow();
    expect(await OutboxStore.all(db), isEmpty);
    expect((await repository.getClientById(created.id!)).isLeft(), true);
    await engine.dispose();
    await databases.close();
  }, skip: url == null ? 'Solo con SYNC_E2E_URL' : null);
}
