import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/clients/data/repositories/client_repository_impl.dart';
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
import 'client_model_test.dart' show backendClient, backendPage;

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

/// Respuesta de `POST /clients/batch` que importa todo lo enviado salvo los
/// teléfonos de [existing].
ResponseBody batchResponse(RequestOptions options,
    {Set<String> existing = const {}}) {
  final rows =
      ((options.data as Map)['clients'] as List).cast<Map<String, dynamic>>();
  final errors = [
    for (final row in rows)
      if (existing.contains(row['phone']))
        {'data': row, 'error': 'Cliente con teléfono ${row['phone']} ya existe'}
  ];
  return jsonBody(201, {
    'imported': [],
    'errors': errors,
    'success': rows.length - errors.length,
    'failed': errors.length,
    'total': rows.length,
  });
}

void main() {
  late FakeHttpClientAdapter adapter;
  late ClientsRepositoryImpl repository;

  setUp(() {
    adapter = FakeHttpClientAdapter((_) => jsonBody(200, {}));
    final dio = buildApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: MemoryTokenStore('jwt'),
      httpClientAdapter: adapter,
      retryDelay: (_) => Duration.zero,
      enableLogs: false,
    );
    repository = ClientsRepositoryImpl(ClientsRemoteDataSourceImpl(dio));
  });

  group('lectura', () {
    test(
        'GET /clients: página tipada, query del PaginationDto, token del núcleo',
        () async {
      adapter.handler = (_) => jsonBody(200,
          backendPage([backendClient(), backendClient(id: 'cli-2')], page: 2));
      final page =
          rightOf(await GetClientsPageUseCase(repository)(const ClientsQuery(
        page: 2,
        search: '  ana ',
        sortBy: ClientSortField.name,
        direction: SortDirection.asc,
        source: ClientSourceFilter.imported,
      )));
      expect(page.items.length, 2);
      expect(page.items.first, isA<ClientEntity>());
      expect(page.hasNextPage, true);

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/clients');
      expect(request.uri.queryParameters, {
        'page': '2',
        'limit': '20',
        'search': 'ana',
        'sortBy': 'name',
        'sortOrder': 'ASC',
        'status': 'all',
        'source': 'imported',
      });
      expect(request.headers['Authorization'], 'Bearer jwt');
      expect(request.headers.containsKey('tenant-id'), false);
    });

    test('sin búsqueda no se envía search; por defecto created_at DESC',
        () async {
      adapter.handler = (_) => jsonBody(200, backendPage([]));
      await repository.getClients(const ClientsQuery(search: '   '));
      final query = adapter.requests.single.uri.queryParameters;
      expect(query.containsKey('search'), false);
      expect(query['sortBy'], 'created_at');
      expect(query['sortOrder'], 'DESC');
    });

    test('página o tamaño fuera de rango → ValidationFailure sin red',
        () async {
      final useCase = GetClientsPageUseCase(repository);
      for (final query in const [
        ClientsQuery(page: 0),
        ClientsQuery(limit: 0),
        ClientsQuery(limit: 101),
      ]) {
        expect(leftOf(await useCase(query)), isA<ValidationFailure>());
      }
      expect(adapter.requests, isEmpty);
    });

    test(
        'GET /clients/:id; id mal formado → 400 BAD_REQUEST → ValidationFailure',
        () async {
      adapter.handler = (_) => jsonBody(200, backendClient());
      expect(
          rightOf(await GetClientByIdUseCase(repository)('cli-1')).id, 'cli-1');
      expect(adapter.requests.single.uri.path, '/api/clients/cli-1');

      adapter.handler =
          (_) => errorBody(400, 'BAD_REQUEST', 'Formato de dato inválido');
      final failure = leftOf(await repository.getClientById('no-uuid'));
      expect(failure, isA<ValidationFailure>());
      expect(failure!.statusCode, 400);
    });

    test('cliente de otro negocio → NotFoundFailure', () async {
      adapter.handler =
          (_) => errorBody(404, 'NOT_FOUND', 'Cliente no encontrado');
      expect(leftOf(await repository.getClientById('cli-x')),
          isA<NotFoundFailure>());
    });

    test('403 → ForbiddenFailure', () async {
      adapter.handler = (_) => errorBody(403, 'FORBIDDEN', 'Sin permiso');
      expect(leftOf(await repository.getClients(const ClientsQuery())),
          isA<ForbiddenFailure>());
    });

    test('sin conexión → NetworkFailure (tras los reintentos del GET)',
        () async {
      adapter.handler = connectionError;
      expect(leftOf(await repository.getClients(const ClientsQuery())),
          isA<NetworkFailure>());
      expect(adapter.requests.length, greaterThan(1));
    });
  });

  group('alta y edición', () {
    test('POST /clients sin email: normalizado y con email ""', () async {
      adapter.handler = (_) => jsonBody(201, backendClient(email: null));
      final created = rightOf(await CreateClientUseCase(repository)(newClient));
      expect(created.email, isNull);

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/clients');
      final body = request.data as Map;
      expect(body['name'], 'Ana');
      expect(body['lastname'], 'Pérez');
      expect(body['email'], '');
      expect(body['phone'], '+573001234567');
      expect(body.containsKey('ownerId'), false);
      expect(body.containsKey('id'), false);
    });

    test('datos inválidos → InvalidClientDataFailure sin llamar al backend',
        () async {
      final failure = leftOf(await CreateClientUseCase(repository)(
          const ClientEntity(
              name: ' ', phone: '300 12', email: 'no-es-email')));
      expect(failure, isA<InvalidClientDataFailure>());
      expect(failure!.details, [
        ClientRules.nameRequired,
        ClientRules.phoneTooShort,
        ClientRules.invalidEmail,
      ]);
      expect(adapter.requests, isEmpty);
    });

    test('409 DUPLICATE_EMAIL → DuplicateClientFailure con el texto del backend',
        () async {
      adapter.handler = (_) => errorBody(409, 'DUPLICATE_EMAIL',
          'Ya existe un cliente con el email: ana@example.com');
      for (final result in [
        await CreateClientUseCase(repository)(newClient),
        await UpdateClientUseCase(repository)(newClient.copyWith(id: 'cli-1')),
      ]) {
        final failure = leftOf(result);
        expect(failure, isA<DuplicateClientFailure>());
        expect(failure, isNot(isA<DuplicateClientPhoneFailure>()));
        expect(failure, isA<ConflictFailure>());
        expect(failure!.message,
            'Ya existe un cliente con el email: ana@example.com');
        expect(failure.code, ApiErrorCode.duplicateEmail);
        expect(failure.statusCode, 409);
      }
    });

    test(
        '409 DUPLICATE_PHONE → DuplicateClientPhoneFailure con el texto del backend',
        () async {
      adapter.handler = (_) => errorBody(409, 'DUPLICATE_PHONE',
          'Ya existe un cliente con el teléfono: 3001234567');
      for (final result in [
        await CreateClientUseCase(repository)(newClient),
        await UpdateClientUseCase(repository)(newClient.copyWith(id: 'cli-1')),
      ]) {
        final failure = leftOf(result);
        expect(failure, isA<DuplicateClientPhoneFailure>());
        expect(failure, isA<DuplicateClientFailure>());
        expect(failure!.code, ApiErrorCode.duplicatePhone);
        expect(failure.message,
            'Ya existe un cliente con el teléfono: 3001234567');
      }
    });

    test('409 CONFLICT al guardar ya no es un duplicado: ConflictFailure genérico',
        () async {
      adapter.handler = (_) => errorBody(409, 'CONFLICT', 'Conflicto');
      final failure = leftOf(await repository.createClient(newClient));
      expect(failure, isA<ConflictFailure>());
      expect(failure, isNot(isA<DuplicateClientFailure>()));
      expect(failure!.code, ApiErrorCode.conflict);
    });

    test('PATCH /clients/:id: email vacío lo quita; sin id → failure local',
        () async {
      adapter.handler = (_) => jsonBody(200, backendClient(email: null));
      final updated = rightOf(await UpdateClientUseCase(repository)(
          newClient.copyWith(id: 'cli-1')));
      expect(updated.email, isNull);
      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.uri.path, '/api/clients/cli-1');
      expect((request.data as Map)['email'], '');

      final failure = leftOf(await UpdateClientUseCase(repository)(newClient));
      expect(failure, isA<InvalidClientDataFailure>());
      expect(adapter.requests.length, 1);
    });
  });

  group('borrado', () {
    test('DELETE /clients/:id (200 sin cuerpo) → Right(unit)', () async {
      adapter.handler = (_) => ResponseBody.fromString('', 200);
      expect(await DeleteClientUseCase(repository)('cli-1'), const Right(unit));
      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.uri.path, '/api/clients/cli-1');
    });

    test('409 CONFLICT (FK de citas) → ClientHasHistoryFailure', () async {
      adapter.handler = (_) => errorBody(409, 'CONFLICT',
          'No se puede realizar la operación porque hay registros relacionados');
      final failure = leftOf(await repository.deleteClient('cli-1'));
      expect(failure, isA<ClientHasHistoryFailure>());
      expect(failure!.message, ClientHasHistoryFailure.defaultMessage);
    });
  });

  group('importación', () {
    test('resultado parcial: rechazados locales y del backend, sin email',
        () async {
      adapter.handler =
          (options) => batchResponse(options, existing: {'3000000002'});
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
        'Cliente con teléfono 3000000002 ya existe',
      ]);

      final rows = ((adapter.requests.single.data as Map)['clients'] as List)
          .cast<Map<String, dynamic>>();
      expect(adapter.requests.single.uri.path, '/api/clients/batch');
      expect(rows.length, 3);
      expect(rows[0]['email'], 'uno@correo.co');
      expect(rows[1].containsKey('email'), false);
      expect(rows[2].containsKey('email'), false,
          reason: 'email inválido fuera');
      expect(rows.any((r) => r['email'] == 'no-email@example.com'), false);
    });

    test('lotes de 50; si falla un lote posterior se detiene con lo importado',
        () async {
      var calls = 0;
      adapter.handler = (options) {
        calls++;
        if (calls == 2) connectionError(options);
        return batchResponse(options);
      };
      final contacts = [for (var i = 0; i < 120; i++) contact(i)];
      final result = rightOf(await ImportClientsUseCase(repository)(contacts));
      expect(adapter.requests.length, 2, reason: 'POST no se reintenta');
      expect(result.requested, 120);
      expect(result.imported, 50);
      expect(result.notSent, 70);
      expect(result.failed, 70);
      expect(result.isComplete, false);
      expect(result.interruption, isA<NetworkFailure>());
    });

    test('si falla el primer lote → Left; lista vacía → failure local',
        () async {
      adapter.handler = (_) => errorBody(403, 'FORBIDDEN', 'Sin permiso');
      expect(leftOf(await ImportClientsUseCase(repository)([contact(1)])),
          isA<ForbiddenFailure>());
      expect(leftOf(await ImportClientsUseCase(repository)(const [])),
          isA<InvalidClientDataFailure>());
      expect(adapter.requests.length, 1);
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
