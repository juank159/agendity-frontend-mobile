import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/features/whatsapp/data/datasources/whatsapp_remote_datasource.dart';
import 'package:login_signup/features/whatsapp/data/models/whatsapp_config_model.dart';
import 'package:login_signup/features/whatsapp/data/repositories/whatsapp_repository_impl.dart';
import 'package:login_signup/features/whatsapp/domain/entities/whatsapp_config.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';

const backendConfig = {
  'id': 'cfg-1',
  'ownerId': 'owner-1',
  'phoneNumber': '573001234567',
  'apiKey': 'k-123',
  'isEnabled': true,
  'createdAt': '2026-10-21T08:00:00.000-05:00',
  'updatedAt': '2026-10-21T08:00:00.000-05:00',
};

void main() {
  group('WhatsappConfigModel', () {
    test('fromJson con la respuesta real del backend', () {
      final model = WhatsappConfigModel.fromJson(backendConfig);
      expect(
          model.toEntity(),
          const WhatsappConfig(
              id: 'cfg-1',
              phoneNumber: '573001234567',
              apiKey: 'k-123',
              isEnabled: true));
    });

    test('fromJson tolerante: nulls y tipos raros', () {
      final model = WhatsappConfigModel.fromJson(
          {'id': null, 'phoneNumber': 573001234567, 'apiKey': null});
      expect(model.id, isNull);
      expect(model.phoneNumber, '573001234567');
      expect(model.apiKey, '');
      expect(model.isEnabled, true);
      expect(
          WhatsappConfigModel.fromJson({'isEnabled': false}).isEnabled, false);
    });

    test('toJson es el DTO del backend (sin id) y fromEntity ida y vuelta', () {
      const entity = WhatsappConfig(
          id: 'cfg-1', phoneNumber: '57300', apiKey: 'k', isEnabled: false);
      final model = WhatsappConfigModel.fromEntity(entity);
      expect(model.toJson(),
          {'phoneNumber': '57300', 'apiKey': 'k', 'isEnabled': false});
      expect(model.toEntity(), entity);
    });
  });

  group('WhatsappRepositoryImpl (Dio api + adaptador falso)', () {
    late FakeHttpClientAdapter adapter;
    late WhatsappRepositoryImpl repository;

    setUp(() {
      adapter = FakeHttpClientAdapter((_) => jsonBody(200, backendConfig));
      final dio = buildApiClient(
        baseUrl: 'http://api.test/api',
        tokenStore: MemoryTokenStore('jwt'),
        httpClientAdapter: adapter,
        retryDelay: (_) => Duration.zero,
        enableLogs: false,
      );
      repository = WhatsappRepositoryImpl(WhatsappRemoteDataSourceImpl(dio));
    });

    Failure? leftOf(Either<Failure, Object?> result) =>
        result.fold((f) => f, (_) => null);

    test('getConfig éxito: GET /whatsapp/config con token del núcleo',
        () async {
      final result = await repository.getConfig();
      expect(result.getOrElse(() => null)?.id, 'cfg-1');
      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/whatsapp/config');
      expect(request.headers['Authorization'], 'Bearer jwt');
      expect(request.headers.containsKey('tenant-id'), false);
    });

    test('getConfig 404 (sin configuración) → Right(null)', () async {
      adapter.handler = (_) => jsonBody(404, {
            'statusCode': 404,
            'code': 'NOT_FOUND',
            'message': 'WhatsApp configuration not found for owner x'
          });
      expect(await repository.getConfig(),
          const Right<Failure, WhatsappConfig?>(null));
    });

    test('getConfig 403 (Employee) → ForbiddenFailure', () async {
      adapter.handler = (_) => jsonBody(403, {
            'statusCode': 403,
            'code': 'FORBIDDEN',
            'message': 'No tienes permiso'
          });
      expect(leftOf(await repository.getConfig()), isA<ForbiddenFailure>());
    });

    test('getConfig sin red → NetworkFailure', () async {
      adapter.handler = connectionError;
      expect(leftOf(await repository.getConfig()), isA<NetworkFailure>());
    });

    test('saveConfig éxito (201) envía el DTO y devuelve la entidad', () async {
      adapter.handler = (_) => jsonBody(201, backendConfig);
      final result = await repository.saveConfig(const WhatsappConfig(
          id: 'cfg-1', phoneNumber: '573001234567', apiKey: 'k-123'));
      expect(result.isRight(), true);
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.data, {
        'phoneNumber': '573001234567',
        'apiKey': 'k-123',
        'isEnabled': true
      });
    });

    test('saveConfig 400 de validación → ValidationFailure con details',
        () async {
      adapter.handler = (_) => jsonBody(400, {
            'statusCode': 400,
            'code': 'VALIDATION_ERROR',
            'message': 'apiKey should not be empty',
            'details': ['apiKey should not be empty']
          });
      final failure = leftOf(await repository
          .saveConfig(const WhatsappConfig(phoneNumber: '57', apiKey: '')));
      expect(failure, isA<ValidationFailure>());
      expect(failure!.details, ['apiKey should not be empty']);
    });

    test('saveConfig 403 → ForbiddenFailure', () async {
      adapter.handler =
          (_) => jsonBody(403, {'statusCode': 403, 'code': 'FORBIDDEN'});
      expect(
          leftOf(await repository.saveConfig(
              const WhatsappConfig(phoneNumber: '57', apiKey: 'k'))),
          isA<ForbiddenFailure>());
    });

    test('sendTestMessage: success true/false del backend', () async {
      adapter.handler =
          (_) => jsonBody(201, {'success': true, 'message': 'Message sent'});
      expect(
          await repository.sendTestMessage(), const Right<Failure, bool>(true));
      adapter.handler = (_) => jsonBody(
          201, {'success': false, 'message': 'Failed to send test message'});
      expect(await repository.sendTestMessage(),
          const Right<Failure, bool>(false));
    });

    test('sendTestMessage sin red → NetworkFailure (sin reintentar POST)',
        () async {
      adapter.handler = connectionError;
      expect(leftOf(await repository.sendTestMessage()), isA<NetworkFailure>());
      expect(adapter.requests, hasLength(1));
    });

    test('respuesta inesperada (cuerpo vacío) → ServerFailure, sin excepción',
        () async {
      adapter.handler = (_) => ResponseBody.fromString('', 200);
      expect(leftOf(await repository.getConfig()), isA<ServerFailure>());
    });
  });
}
