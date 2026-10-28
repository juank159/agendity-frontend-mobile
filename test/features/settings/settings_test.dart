import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:login_signup/features/settings/data/models/business_settings_model.dart';
import 'package:login_signup/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/failures/settings_failures.dart';
import 'package:login_signup/features/settings/domain/usecases/get_business_settings_usecase.dart';
import 'package:login_signup/features/settings/domain/usecases/update_business_time_zone_usecase.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';

Failure? leftOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => null);

T rightOf<T>(Either<Failure, T> result) =>
    result.getOrElse(() => throw StateError('Left: ${leftOf(result)}'));

void main() {
  late FakeHttpClientAdapter adapter;
  late MemoryTimeZoneStore zones;
  late SessionService session;
  late SettingsRepositoryImpl repository;

  setUp(() {
    adapter = FakeHttpClientAdapter(
        (_) => jsonBody(200, {'timezone': 'America/Caracas'}));
    final tokens = MemoryTokenStore('jwt');
    zones = MemoryTimeZoneStore();
    session = SessionService(
        tokenStore: tokens,
        repository: SessionRepository(tokens),
        timeZoneStore: zones);
    repository = SettingsRepositoryImpl(
      remote: SettingsRemoteDataSourceImpl(buildApiClient(
        baseUrl: 'http://api.test/api',
        tokenStore: tokens,
        httpClientAdapter: adapter,
        retryDelay: (_) => Duration.zero,
        enableLogs: false,
      )),
      session: session,
    );
  });

  tearDown(BusinessTimeZone.reset);

  group('BusinessSettingsModel', () {
    test('fromJson y toEntity', () {
      expect(
          BusinessSettingsModel.fromJson({'timezone': 'America/Bogota'})
              .toEntity(),
          const BusinessSettings(timeZone: 'America/Bogota'));
    });

    test('sin timezone → FormatException', () {
      for (final json in [null, <String, dynamic>{}, {'timezone': ' '}]) {
        expect(() => BusinessSettingsModel.fromJson(json),
            throwsFormatException);
      }
    });

    test('cuerpo del PATCH', () {
      expect(BusinessSettingsModel.timeZoneUpdate('America/Caracas'),
          {'timezone': 'America/Caracas'});
    });
  });

  group('leer (GET /settings)', () {
    test('con token; la zona pasa a la sesión', () async {
      final settings =
          rightOf(await GetBusinessSettingsUseCase(repository)(NoParams()));
      expect(settings.timeZone, 'America/Caracas');
      final request = adapter.requests.single;
      expect('${request.method} ${request.uri.path}', 'GET /api/settings');
      expect(request.headers['Authorization'], 'Bearer jwt');
      expect(session.timeZone, 'America/Caracas');
      expect(BusinessTimeZone.current, 'America/Caracas');
      expect(zones.timeZone, 'America/Caracas');
    });

    test('respuesta sin zona → ServerFailure y la sesión no cambia',
        () async {
      adapter.handler = (_) => jsonBody(200, <String, dynamic>{});
      expect(leftOf(await repository.getSettings()), isA<ServerFailure>());
      expect(BusinessTimeZone.current, BusinessTimeZone.fallback);
    });
  });

  group('cambiar la zona (PATCH /settings)', () {
    test('envía la zona canónica y la sesión pasa a la nueva', () async {
      final settings = rightOf(
          await UpdateBusinessTimeZoneUseCase(repository)(' america/caracas '));
      expect(settings, const BusinessSettings(timeZone: 'America/Caracas'));
      final request = adapter.requests.single;
      expect('${request.method} ${request.uri.path}', 'PATCH /api/settings');
      expect(request.data, {'timezone': 'America/Caracas'});
      expect(BusinessTimeZone.current, 'America/Caracas');
    });

    test('zona desconocida → InvalidTimeZoneFailure sin llamar al backend',
        () async {
      for (final zone in ['', 'GMT-5', 'Marte/Olympus']) {
        expect(leftOf(await UpdateBusinessTimeZoneUseCase(repository)(zone)),
            isA<InvalidTimeZoneFailure>(),
            reason: zone);
      }
      expect(adapter.requests, isEmpty);
    });

    test('Employee (403) → ForbiddenFailure y la zona no cambia', () async {
      await session.applyTimeZone('America/Bogota');
      adapter.handler = (_) => jsonBody(403, {
            'statusCode': 403,
            'code': 'FORBIDDEN',
            'message': 'No tienes permiso',
          });
      expect(leftOf(await repository.updateTimeZone('America/Caracas')),
          isA<ForbiddenFailure>());
      expect(BusinessTimeZone.current, 'America/Bogota');
    });

    test('400 VALIDATION_ERROR del backend → ValidationFailure', () async {
      adapter.handler = (_) => jsonBody(400, {
            'statusCode': 400,
            'code': 'VALIDATION_ERROR',
            'message': 'Zona horaria inválida',
          });
      final failure = leftOf(await repository.updateTimeZone('Europe/Madrid'));
      expect(failure, isA<ValidationFailure>());
      expect(failure!.message, 'Zona horaria inválida');
    });
  });

  test('BusinessSettings: igualdad y copyWith', () {
    const a = BusinessSettings(timeZone: 'America/Bogota');
    expect(a.copyWith(), a);
    expect(a.copyWith(timeZone: 'America/Caracas'),
        const BusinessSettings(timeZone: 'America/Caracas'));
    expect(a.hashCode, const BusinessSettings(timeZone: 'America/Bogota').hashCode);
  });
}
