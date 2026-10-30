import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:login_signup/features/settings/data/models/business_settings_model.dart';
import 'package:login_signup/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/failures/settings_failures.dart';
import 'package:login_signup/features/settings/domain/usecases/business_settings_rules.dart';
import 'package:login_signup/features/settings/domain/usecases/update_business_name_usecase.dart';
import 'package:login_signup/features/settings/domain/usecases/update_opening_hours_usecase.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';

OpeningHoursRange range(int day, String start, String end) =>
    OpeningHoursRange(dayOfWeek: day, hours: WorkHours(start: start, end: end));

Failure? leftOf(Either<Failure, Object?> r) => r.fold((f) => f, (_) => null);

/// Nombre, slug y horario de apertura del negocio (8.00, 8.01).
void main() {
  group('BusinessSettingsModel', () {
    test('respuesta completa del backend', () {
      final settings = BusinessSettingsModel.fromJson({
        'timezone': 'America/Bogota',
        'name': 'Estudio Cejas & Pestañas',
        'slug': 'estudio-cejas-pestanas',
        'opening_hours': [
          {'day_of_week': 2, 'start_time': '09:00', 'end_time': '13:00'},
          {'day_of_week': 1, 'start_time': '09:00:00', 'end_time': '18:00'},
          {'day_of_week': 2, 'start_time': '14:00', 'end_time': '19:00'},
          {'day_of_week': 9, 'start_time': '09:00', 'end_time': '10:00'},
        ],
      }).toEntity();
      expect(settings.name, 'Estudio Cejas & Pestañas');
      expect(settings.slug, 'estudio-cejas-pestanas');
      final hours = settings.openingHours!;
      expect(hours.ranges, [
        range(1, '09:00', '18:00'),
        range(2, '09:00', '13:00'),
        range(2, '14:00', '19:00'),
      ], reason: 'ordenadas, normalizadas y sin el día 9');
      expect(hours.isClosedOn(7), true);
      expect(hours.rangesOn(2).length, 2);
    });

    test('sin horario (null) ≠ cerrado todos los días ([])', () {
      final none = BusinessSettingsModel.fromJson(
          {'timezone': 'America/Bogota', 'opening_hours': null}).toEntity();
      expect(none.openingHours, isNull);
      expect(none.hasOpeningHours, false);
      expect(none.name, isNull);
      final closed = BusinessSettingsModel.fromJson(
          {'timezone': 'America/Bogota', 'opening_hours': []}).toEntity();
      expect(closed.openingHours, OpeningHours.closed);
    });

    test('cuerpos del PATCH', () {
      expect(BusinessSettingsModel.nameUpdate('Salón'), {'name': 'Salón'});
      expect(BusinessSettingsModel.openingHoursUpdate(null),
          {'opening_hours': null});
      expect(
          BusinessSettingsModel.openingHoursUpdate(
              OpeningHours([range(1, '09:00', '18:00')])),
          {
            'opening_hours': [
              {'day_of_week': 1, 'start_time': '09:00', 'end_time': '18:00'}
            ]
          });
    });
  });

  group('reglas del horario', () {
    Failure? check(List<OpeningHoursRange> ranges) =>
        BusinessSettingsRules.checkOpeningHours(
            BusinessSettingsRules.normalize(OpeningHours(ranges)));

    test('válido: varias franjas que se tocan sin pisarse', () {
      expect(
          check([
            range(1, '09:00', '12:00'),
            range(1, '12:00', '18:00'),
            range(2, '10:00', '14:00'),
          ]),
          isNull);
      expect(check(const []), isNull, reason: 'cerrado todos los días');
    });

    test('apertura después del cierre o igual', () {
      final failure = check([range(3, '18:00', '09:00')]);
      expect(failure, isA<InvalidOpeningHoursFailure>());
      expect(failure!.message, contains('miércoles'));
      expect(check([range(3, '09:00', '09:00')]),
          isA<InvalidOpeningHoursFailure>());
    });

    test('franjas del mismo día que se pisan', () {
      final failure =
          check([range(5, '09:00', '13:00'), range(5, '12:00', '18:00')]);
      expect(failure, isA<InvalidOpeningHoursFailure>());
      expect(failure!.message, contains('viernes'));
      expect(failure.message, contains('se pisan'));
      expect(check([range(5, '09:00', '13:00'), range(6, '12:00', '18:00')]),
          isNull, reason: 'otro día');
    });

    test('hora o día inválidos y demasiadas franjas', () {
      expect(check([range(1, '9:00', '18:00')]),
          isA<InvalidOpeningHoursFailure>());
      expect(check([range(0, '09:00', '18:00')]),
          isA<InvalidOpeningHoursFailure>());
      expect(
          check([
            for (var i = 0; i < 29; i++)
              range(1 + i % 7, '${(i ~/ 7).toString().padLeft(2, '0')}:00',
                  '${(i ~/ 7).toString().padLeft(2, '0')}:30')
          ]),
          isA<InvalidOpeningHoursFailure>());
    });

    test('withDay sustituye solo ese día', () {
      final hours = OpeningHours([range(1, '09:00', '18:00')])
          .withDay(2, const [WorkHours(start: '10:00', end: '14:00')])
          .withDay(1, const []);
      expect(hours.ranges, [range(2, '10:00', '14:00')]);
    });
  });

  group('use cases', () {
    late FakeHttpClientAdapter adapter;
    late SettingsRepositoryImpl repository;

    setUp(() {
      adapter = FakeHttpClientAdapter((request) => jsonBody(200, {
            'timezone': 'America/Bogota',
            'name': 'Salón Ana',
            'slug': 'salon-ana',
            'opening_hours': null,
          }));
      final tokens = MemoryTokenStore('jwt');
      repository = SettingsRepositoryImpl(
        remote: SettingsRemoteDataSourceImpl(buildApiClient(
            baseUrl: 'http://api.test/api',
            tokenStore: tokens,
            httpClientAdapter: adapter,
            enableLogs: false)),
        session: SessionService(
            tokenStore: tokens, repository: SessionRepository(tokens)),
      );
    });

    tearDown(BusinessTimeZone.reset);

    test('nombre: recortado y validado; el slug lo da el backend', () async {
      final result =
          await UpdateBusinessNameUseCase(repository)('  Salón Ana  ');
      expect(result.getOrElse(() => throw StateError('')).slug, 'salon-ana');
      expect(adapter.requests.single.data, {'name': 'Salón Ana'});

      for (final bad in ['', ' A ', 'x' * 101]) {
        expect(leftOf(await UpdateBusinessNameUseCase(repository)(bad)),
            isA<InvalidBusinessNameFailure>());
      }
      expect(adapter.requests.length, 1);
    });

    test('horario: valida antes de enviar; null lo quita', () async {
      expect(
          leftOf(await UpdateOpeningHoursUseCase(repository)(OpeningHours([
            range(1, '09:00', '13:00'),
            range(1, '10:00', '18:00'),
          ]))),
          isA<InvalidOpeningHoursFailure>());
      expect(adapter.requests, isEmpty);

      await UpdateOpeningHoursUseCase(repository)(
          OpeningHours([range(1, '09:00:00', '18:00')]));
      expect(adapter.requests.last.data, {
        'opening_hours': [
          {'day_of_week': 1, 'start_time': '09:00', 'end_time': '18:00'}
        ]
      });

      await UpdateOpeningHoursUseCase(repository)(null);
      expect(adapter.requests.last.data, {'opening_hours': null});
      expect(adapter.requests.last.method, 'PATCH');
    });

    test('400 del backend (cierre antes de apertura) → ValidationFailure',
        () async {
      adapter.handler = (_) => jsonBody(400, {
            'statusCode': 400,
            'code': 'VALIDATION_ERROR',
            'message': 'La hora de cierre (09:00) debe ser posterior',
          });
      expect(
          leftOf(await repository
              .updateOpeningHours(OpeningHours([range(1, '09:00', '18:00')]))),
          isA<ValidationFailure>());
    });
  });

  test('copyWith: clearOpeningHours deja sin horario', () {
    final settings = BusinessSettings(
        timeZone: 'America/Bogota', openingHours: OpeningHours.closed);
    expect(settings.copyWith(clearOpeningHours: true).openingHours, isNull);
    expect(settings.copyWith(name: 'X').openingHours, OpeningHours.closed);
  });
}
