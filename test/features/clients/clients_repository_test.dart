import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/features/clients/data/datasources/clients_local_datasource.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/clients/data/repositories/client_repository_impl.dart';
import 'package:login_signup/features/clients/data/sync/clients_sync_handler.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/features/clients/domain/failures/client_failures.dart';
import 'package:login_signup/features/clients/domain/usecases/client_rules.dart';
import 'package:login_signup/features/clients/domain/usecases/create_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/delete_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/get_client_by_id_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/get_clients_page_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/import_clients_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/update_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/upload_client_image_usecase.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';
import '../../core/sync/fake_sync_api.dart';
import 'client_model_test.dart' show backendClient;

Failure? leftOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => null);

T rightOf<T>(Either<Failure, T> result) =>
    result.getOrElse(() => throw StateError('Left: ${leftOf(result)}'));

ResponseBody errorBody(int status, String code, String message) =>
    jsonBody(status, {'statusCode': status, 'code': code, 'message': message});

const newClient = ClientEntity(
  name: '  Ana ',
  lastname: 'Pérez ',
  email: '  ',
  phone: '+57 300-123 4567',
);

/// Contacto del teléfono con un número de 10 dígitos que depende de [i].
ClientEntity contact(int i, {String? email}) => ClientEntity(
      name: 'Contacto $i',
      phone: '300${i.toString().padLeft(7, '0')}',
      email: email,
    );

/// Repositorio de clientes sin conexión (10.02): lee la base local, escribe
/// en local + bandeja. La red solo se usa para la foto.
void main() {
  late FakeHttpClientAdapter adapter;
  late LocalDatabaseHolder databases;
  late ClientsRepositoryImpl repository;
  late AppDatabase db;
  late int writes;
  var ids = 0;

  setUp(() async {
    adapter = FakeHttpClientAdapter((_) => jsonBody(200, {}));
    final dio = buildApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: MemoryTokenStore('jwt'),
      httpClientAdapter: adapter,
      retryDelay: (_) => Duration.zero,
      enableLogs: false,
    );
    databases = memoryDatabases();
    writes = 0;
    ids = 0;
    repository = ClientsRepositoryImpl(
      remote: ClientsRemoteDataSourceImpl(dio),
      store: OfflineStore(
        databases: databases,
        clock: () => DateTime.utc(2026, 10, 31, 15),
        newId: () => '0192d000-0000-7000-8000-${(++ids).toString().padLeft(12, '0')}',
        onWrite: () => writes++,
      ),
    );
    db = await databases.require();
  });

  tearDown(() => databases.close());

  /// Clientes que bajaron del servidor.
  Future<void> seed(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await const ClientsLocalDataSource()
          .upsertFields(db, row['id'] as String, row);
    }
  }

  group('lectura (siempre local, sin red)', () {
    setUp(() => seed([
          backendClient(id: 'c1', name: 'Ana', phone: '3000000001'),
          {
            ...backendClient(id: 'c2', name: 'Beto', phone: '3000000002'),
            'isFromDevice': true,
            'created_at': '2026-10-22T08:00:00.000-05:00',
          },
          {
            ...backendClient(id: 'c3', name: 'Carla', phone: '3000000003'),
            'isActive': false,
            'email': 'carla@correo.co',
            'created_at': '2026-10-23T08:00:00.000-05:00',
          },
        ]));

    test('por defecto: más recientes primero, con metadatos de página',
        () async {
      final page = rightOf(
          await GetClientsPageUseCase(repository)(const ClientsQuery()));
      expect(page.items.map((c) => c.id), ['c3', 'c2', 'c1']);
      expect(page.total, 3);
      expect(page.totalPages, 1);
      expect(adapter.requests, isEmpty);
    });

    test('búsqueda en nombre, email y teléfono (sin mayúsculas)', () async {
      Future<List<String?>> search(String text) async =>
          rightOf(await repository.getClients(ClientsQuery(search: text)))
              .items
              .map((c) => c.id)
              .toList();
      expect(await search('CARLA@'), ['c3']);
      expect(await search('0000002'), ['c2']);
      expect(await search(' BETO '), ['c2']);
      expect(await search('beto pérez'), ['c2'], reason: 'nombre completo');
      expect(await search('100%'), isEmpty, reason: 'comodines escapados');
    });

    test('filtros de estado y origen, orden y paginación', () async {
      expect(
          rightOf(await repository.getClients(
                  const ClientsQuery(status: ClientStatusFilter.inactive)))
              .items
              .single
              .id,
          'c3');
      expect(
          rightOf(await repository.getClients(
                  const ClientsQuery(source: ClientSourceFilter.imported)))
              .items
              .single
              .id,
          'c2');
      final page2 = rightOf(await repository.getClients(const ClientsQuery(
          page: 2,
          limit: 2,
          sortBy: ClientSortField.name,
          direction: SortDirection.asc)));
      expect(page2.items.map((c) => c.name), ['Carla']);
      expect(page2.hasPrevPage, true);
      expect(page2.hasNextPage, false);
    });

    test('página o tamaño fuera de rango → ValidationFailure', () async {
      final useCase = GetClientsPageUseCase(repository);
      for (final query in const [
        ClientsQuery(page: 0),
        ClientsQuery(limit: 0),
        ClientsQuery(limit: 101),
      ]) {
        expect(leftOf(await useCase(query)), isA<ValidationFailure>());
      }
    });

    test('por id; inexistente → NotFoundFailure', () async {
      expect(rightOf(await GetClientByIdUseCase(repository)('c1')).name, 'Ana');
      expect(leftOf(await repository.getClientById('no-existe')),
          isA<NotFoundFailure>());
    });

    test('sin sesión → failure, sin lanzar', () async {
      final none = ClientsRepositoryImpl(
        remote: ClientsRemoteDataSourceImpl(Dio()),
        store: OfflineStore(databases: memoryDatabases(userId: () => null)),
      );
      expect(leftOf(await none.getClients(const ClientsQuery())),
          isA<Failure>());
    });
  });

  group('alta, edición y borrado (local + bandeja)', () {
    test('alta: id UUID v7 de la app, normalizada, en local y en la bandeja',
        () async {
      final created = rightOf(await CreateClientUseCase(repository)(newClient));
      expect(created.id, startsWith('0192d000'));
      expect(created.name, 'Ana');
      expect(created.phone, '+573001234567');
      expect(created.email, isNull);
      expect(created.createdAt, isNotNull);

      final entry = (await OutboxStore.all(db)).single;
      expect(entry.type, 'client.create');
      expect(entry.entity, 'clients');
      expect(entry.entityId, created.id);
      expect(entry.payload['phone'], '+573001234567');
      expect(entry.payload.containsKey('id'), false);
      expect(entry.clientTime, '2026-10-31T15:00:00.000Z');
      expect(writes, 1, reason: 'avisa al motor');
      expect(adapter.requests, isEmpty, reason: 'nada va a la red');
      expect(rightOf(await repository.getClientById(created.id!)).name, 'Ana');
    });

    test('teléfono o email repetidos en local → failures de duplicado',
        () async {
      await seed([
        {...backendClient(id: 'c1', phone: '+573001234567'), 'email': 'a@b.co'}
      ]);
      final phone = leftOf(await repository.createClient(
          const ClientEntity(name: 'X', phone: '+573001234567')));
      expect(phone, isA<DuplicateClientPhoneFailure>());
      expect(phone!.message, 'Ya existe un cliente con el teléfono: +573001234567');
      expect(
          leftOf(await repository.createClient(const ClientEntity(
              name: 'X', phone: '3110000000', email: 'A@B.CO'))),
          isA<DuplicateClientFailure>());
      expect(await OutboxStore.all(db), isEmpty);
    });

    test('datos inválidos → InvalidClientDataFailure sin escribir', () async {
      expect(
          leftOf(await CreateClientUseCase(repository)(
              const ClientEntity(name: '', phone: '12'))),
          isA<InvalidClientDataFailure>());
      expect(await OutboxStore.all(db), isEmpty);
    });

    test('edición: solo los campos que cambian; sin cambios no encola',
        () async {
      await seed([backendClient(id: 'c1', name: 'Ana', phone: '3000000001')]);
      final current = rightOf(await repository.getClientById('c1'));
      final edited = rightOf(await UpdateClientUseCase(repository)(
          current.copyWith(name: 'Ana María', notes: 'VIP')));
      expect(edited.name, 'Ana María');
      final entry = (await OutboxStore.all(db)).single;
      expect(entry.type, 'client.update');
      expect(entry.payload, {'name': 'Ana María', 'notes': 'VIP'});

      rightOf(await repository.updateClient(edited));
      expect((await OutboxStore.all(db)).length, 1);
    });

    test('edición de uno inexistente → NotFoundFailure', () async {
      expect(
          leftOf(await repository.updateClient(
              const ClientEntity(id: 'nada', name: 'X', phone: '3000000009'))),
          isA<NotFoundFailure>());
    });

    test('borrado: desaparece en local y queda client.delete', () async {
      await seed([backendClient(id: 'c1', phone: '3000000001')]);
      rightOf(await DeleteClientUseCase(repository)('c1'));
      expect(leftOf(await repository.getClientById('c1')),
          isA<NotFoundFailure>());
      expect((await OutboxStore.all(db)).single.type, 'client.delete');
    });

    test('de punta a punta con el motor: sube y lo local queda igual al '
        'servidor', () async {
      final server = FakeSyncServer();
      final engine = SyncEngine(
          databases: databases,
          api: server,
          handlers: [ClientsSyncHandler(const ClientsLocalDataSource())]);
      final created = rightOf(await repository.createClient(
          const ClientEntity(name: 'Ana', phone: '3001112222')));
      await engine.syncNow();
      expect(server.clients.keys, [created.id]);
      expect(await OutboxStore.all(db), isEmpty);
      final local = rightOf(await repository.getClientById(created.id!));
      expect(local.isActive, true);
      await engine.dispose();
    });
  });

  group('importación', () {
    test('rechazos locales (reglas y teléfonos ya registrados), sin red',
        () async {
      await seed([backendClient(id: 'c1', phone: '3000000002')]);
      final result = rightOf(await ImportClientsUseCase(repository)([
        contact(1, email: 'uno@correo.co'),
        contact(2),
        contact(3, email: 'roto@'),
        contact(1), // teléfono repetido en la lista
        const ClientEntity(name: 'Sin teléfono', phone: '123'),
        const ClientEntity(name: '', phone: '3009999999'),
      ]));

      expect(result.requested, 6);
      expect(result.imported, 2);
      expect(result.failed, 4);
      expect(result.isComplete, true);
      expect(result.rejected.map((r) => r.reason), [
        ImportClientsUseCase.repeatedPhone,
        ClientRules.phoneTooShort,
        ClientRules.nameRequired,
        'Ya existe un cliente con el teléfono: 3000000002',
      ]);
      final entries = await OutboxStore.all(db);
      expect(entries.map((e) => e.type), ['client.create', 'client.create']);
      expect(entries.first.payload['email'], 'uno@correo.co');
      expect(adapter.requests, isEmpty);
    });

    test('lotes de 50: todos en la bandeja; lista vacía → failure local',
        () async {
      final result = rightOf(await ImportClientsUseCase(repository)(
          [for (var i = 0; i < 120; i++) contact(i)]));
      expect(result.imported, 120);
      expect((await OutboxStore.all(db)).length, 120);
      expect(leftOf(await ImportClientsUseCase(repository)(const [])),
          isA<InvalidClientDataFailure>());
    });
  });

  group('imagen', () {
    late Directory tempDir;

    setUp(() => tempDir = Directory.systemTemp.createTempSync('clients_test'));
    tearDown(() => tempDir.deleteSync(recursive: true));

    test('POST /upload/image?folder=clients (multipart) → URL', () async {
      final file = File('${tempDir.path}/foto.png')
        ..writeAsBytesSync(img.encodePng(img.Image(width: 1200, height: 10)));
      adapter.handler = (_) => jsonBody(
          201, {'url': 'https://cdn/x.jpg', 'message': 'Imagen cargada'});
      expect(rightOf(await UploadClientImageUseCase(repository)(file.path)),
          'https://cdn/x.jpg');
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/upload/image');
      expect(request.uri.queryParameters['folder'], 'clients');
      expect(request.data, isA<FormData>());
      expect(request.headers['Authorization'], 'Bearer jwt');
    });

    test('archivo inexistente → InvalidClientDataFailure sin llamar al backend',
        () async {
      final failure = leftOf(await UploadClientImageUseCase(repository)(
          '${tempDir.path}/no-existe.jpg'));
      expect(failure, isA<InvalidClientDataFailure>());
      expect(failure!.message, ClientsRemoteDataSourceImpl.unreadableImage);
      expect(adapter.requests, isEmpty);
    });

    test('400 del backend (tipo no permitido) → ValidationFailure', () async {
      final file = File('${tempDir.path}/foto.png')
        ..writeAsBytesSync(img.encodePng(img.Image(width: 10, height: 10)));
      adapter.handler =
          (_) => errorBody(400, 'BAD_REQUEST', 'Tipo de archivo no permitido');
      final failure = leftOf(await repository.uploadImage(file.path));
      expect(failure, isA<ValidationFailure>());
      expect(failure!.message, 'Tipo de archivo no permitido');
    });
  });


  group('ClientRules', () {
    test('normalizePhone conserva el + inicial y quita lo demás', () {
      expect(
          ClientRules.normalizePhone(' +57 (300) 123-4567 '), '+573001234567');
      expect(ClientRules.normalizePhone('300 123 4567'), '3001234567');
      expect(ClientRules.normalizePhone('30+0'), '300');
    });
  });
}
