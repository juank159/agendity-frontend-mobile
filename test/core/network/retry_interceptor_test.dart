import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/network/interceptors/retry_interceptor.dart';

import '../session/memory_token_store.dart';
import 'fake_http_client_adapter.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late Dio dio;

  setUp(() {
    adapter = FakeHttpClientAdapter(connectionError);
    dio = buildApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: MemoryTokenStore(),
      httpClientAdapter: adapter,
      retryDelay: (_) => Duration.zero,
      enableLogs: false,
    );
  });

  test('GET sin conexión se reintenta y puede recuperarse', () async {
    var calls = 0;
    adapter.handler = (options) {
      calls++;
      if (calls < 3) connectionError(options);
      return jsonBody(200, {'ok': true});
    };

    final response = await dio.get('/clients');
    expect(response.statusCode, 200);
    expect(adapter.requests, hasLength(3));
  });

  test('GET sin conexión: 1 intento + 3 reintentos y luego el error', () async {
    await expectLater(
      dio.get('/clients'),
      throwsA(isA<DioException>()
          .having((e) => e.type, 'type', DioExceptionType.connectionError)),
    );
    expect(adapter.requests, hasLength(4));
  });

  for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
    test('$method sin conexión NO se reintenta', () async {
      await expectLater(
        dio.request('/appointments', options: Options(method: method)),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, hasLength(1));
    });
  }

  test('GET con 500 NO se reintenta', () async {
    adapter.handler = (_) => jsonBody(500, {'statusCode': 500});
    await expectLater(dio.get('/clients'), throwsA(isA<DioException>()));
    expect(adapter.requests, hasLength(1));
  });

  test('GET con receiveTimeout NO se reintenta', () async {
    adapter.handler = (options) => throw DioException.receiveTimeout(
        timeout: const Duration(seconds: 30), requestOptions: options);
    await expectLater(dio.get('/clients'), throwsA(isA<DioException>()));
    expect(adapter.requests, hasLength(1));
  });

  test('shouldRetry: solo GET/HEAD/OPTIONS con error de conexión', () {
    DioException e(String method, DioExceptionType type) => DioException(
        requestOptions: RequestOptions(path: '/x', method: method), type: type);

    expect(
        RetryInterceptor.shouldRetry(
            e('get', DioExceptionType.connectionError)),
        true);
    expect(
        RetryInterceptor.shouldRetry(
            e('HEAD', DioExceptionType.connectionTimeout)),
        true);
    expect(
        RetryInterceptor.shouldRetry(
            e('OPTIONS', DioExceptionType.connectionError)),
        true);
    expect(
        RetryInterceptor.shouldRetry(
            e('POST', DioExceptionType.connectionError)),
        false);
    expect(RetryInterceptor.shouldRetry(e('GET', DioExceptionType.sendTimeout)),
        false);
    expect(RetryInterceptor.shouldRetry(e('GET', DioExceptionType.badResponse)),
        false);
  });
}
