import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/network/safe_call.dart';

import '../session/memory_token_store.dart';
import 'fake_http_client_adapter.dart';

class _SlotUnavailable extends ConflictFailure {
  const _SlotUnavailable() : super(message: 'slot');
}

void main() {
  late FakeHttpClientAdapter adapter;
  late Dio dio;

  setUp(() {
    adapter = FakeHttpClientAdapter((_) => jsonBody(200, {'id': '1'}));
    dio = buildApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: MemoryTokenStore(),
      httpClientAdapter: adapter,
      retryDelay: (_) => Duration.zero,
      enableLogs: false,
    );
  });

  Future<String> getId() async {
    final response = await dio.get<Map<String, dynamic>>('/clients/1');
    return response.data!['id'] as String;
  }

  test('éxito → Right', () async {
    expect(await safeCall(getId), const Right<Failure, String>('1'));
  });

  test('cualquier 2xx es éxito (201)', () async {
    adapter.handler = (_) => jsonBody(201, {'id': '2'});
    expect(await safeCall(getId), const Right<Failure, String>('2'));
  });

  test('validateStatus por defecto: un 404 es Left(NotFoundFailure)', () async {
    adapter.handler = (_) => jsonBody(
        404, {'statusCode': 404, 'code': 'NOT_FOUND', 'message': 'No existe'});
    final result = await safeCall(getId);
    expect(
        result.fold((f) => f, (_) => null),
        isA<NotFoundFailure>()
            .having((f) => f.message, 'message', 'No existe'));
  });

  test('sin conexión → Left(NetworkFailure)', () async {
    adapter.handler = connectionError;
    final result = await safeCall(getId);
    expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
  });

  test('error al parsear (TypeError) → Left(ServerFailure)', () async {
    adapter.handler = (_) => jsonBody(200, {'id': 1});
    final result = await safeCall(getId);
    expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
  });

  test('refine convierte el failure genérico en uno de la feature', () async {
    adapter.handler = (_) => jsonBody(400, {
          'statusCode': 400,
          'code': 'SLOT_UNAVAILABLE',
          'message': 'Horario no disponible'
        });
    final result = await safeCall(
      getId,
      refine: (f) =>
          f.code == ApiErrorCode.slotUnavailable ? const _SlotUnavailable() : f,
    );
    expect(result.fold((f) => f, (_) => null), isA<_SlotUnavailable>());
  });
}
