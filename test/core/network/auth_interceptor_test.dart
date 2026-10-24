import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/network/interceptors/auth_interceptor.dart';
import 'package:login_signup/core/session/token_store.dart';

import 'fake_http_client_adapter.dart';

class FakeTokenStore implements TokenStore {
  FakeTokenStore(this.token);
  String? token;

  @override
  Future<String?> readToken() async => token;
}

void main() {
  late FakeTokenStore tokens;
  late FakeHttpClientAdapter adapter;
  late int expiredCalls;
  late Dio dio;

  setUp(() {
    tokens = FakeTokenStore('jwt-1');
    adapter = FakeHttpClientAdapter((_) => jsonBody(200, {'ok': true}));
    expiredCalls = 0;
    dio = buildApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: tokens,
      onSessionExpired: () => expiredCalls++,
      httpClientAdapter: adapter,
      enableLogs: false,
    );
  });

  test('con token pone Authorization: Bearer', () async {
    await dio.get('/clients');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer jwt-1');
  });

  test('sin token no pone Authorization', () async {
    tokens.token = null;
    await dio.get('/clients');
    expect(adapter.requests.single.headers.containsKey('Authorization'), false);
  });

  test('token vacío cuenta como sin token', () async {
    tokens.token = '';
    await dio.get('/clients');
    expect(adapter.requests.single.headers.containsKey('Authorization'), false);
  });

  test('ruta pública no lleva token', () async {
    await dio.post('/auth/login',
        options: Options(extra: {AuthInterceptor.publicKey: true}));
    expect(adapter.requests.single.headers.containsKey('Authorization'), false);
  });

  test('401 con token → avisa de la sesión expirada y propaga el error',
      () async {
    adapter.handler = (_) => jsonBody(401, {
          'statusCode': 401,
          'code': 'UNAUTHORIZED',
          'message': 'No autorizado'
        });

    await expectLater(
      dio.get('/clients'),
      throwsA(isA<DioException>()
          .having((e) => e.response?.statusCode, 'status', 401)),
    );
    expect(expiredCalls, 1);
  });

  test('varios 401 con el mismo token avisan una sola vez', () async {
    adapter.handler = (_) => jsonBody(401, {'statusCode': 401});

    await Future.wait([
      dio
          .get('/a')
          .catchError((_) => Response(requestOptions: RequestOptions())),
      dio
          .get('/b')
          .catchError((_) => Response(requestOptions: RequestOptions())),
    ]);
    expect(expiredCalls, 1);

    // Con un token nuevo (nuevo login) vuelve a avisar.
    tokens.token = 'jwt-2';
    await dio
        .get('/c')
        .catchError((_) => Response(requestOptions: RequestOptions()));
    expect(expiredCalls, 2);
  });

  test('401 de una ruta pública (credenciales inválidas) no cierra sesión',
      () async {
    adapter.handler = (_) => jsonBody(401, {
          'statusCode': 401,
          'code': 'UNAUTHORIZED',
          'message': 'Credenciales inválidas'
        });

    await expectLater(
      dio.post('/auth/login',
          options: Options(extra: {AuthInterceptor.publicKey: true})),
      throwsA(isA<DioException>()),
    );
    expect(expiredCalls, 0);
  });

  test('401 sin token enviado no avisa', () async {
    tokens.token = null;
    adapter.handler = (_) => jsonBody(401, {'statusCode': 401});
    await expectLater(dio.get('/clients'), throwsA(isA<DioException>()));
    expect(expiredCalls, 0);
  });

  test('403 no avisa de sesión expirada', () async {
    adapter.handler = (_) => jsonBody(403, {'statusCode': 403});
    await expectLater(dio.get('/clients'), throwsA(isA<DioException>()));
    expect(expiredCalls, 0);
  });

  test('si el callback falla, el error original llega igual', () async {
    dio = buildApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: tokens,
      onSessionExpired: () => throw StateError('boom'),
      httpClientAdapter: adapter,
      enableLogs: false,
    );
    adapter.handler = (_) => jsonBody(401, {'statusCode': 401});
    await expectLater(
      dio.get('/clients'),
      throwsA(isA<DioException>()
          .having((e) => e.response?.statusCode, 'status', 401)),
    );
  });
}
