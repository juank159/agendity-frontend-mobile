import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef FakeHandler = FutureOr<ResponseBody> Function(RequestOptions options);

/// `HttpClientAdapter` falso: no abre sockets. Guarda cada petición y responde
/// con [handler] (que también puede lanzar un `DioException` de red).
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.handler);

  FakeHandler handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ResponseBody textBody(int status, String body) => ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['text/html'],
      },
    );

Never connectionError(RequestOptions options) =>
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'fake: sin conexión',
    );
