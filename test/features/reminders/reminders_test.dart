import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/reminders/data/datasources/reminders_remote_datasource.dart';
import 'package:login_signup/features/reminders/data/models/reminder_models.dart';
import 'package:login_signup/features/reminders/data/repositories/reminders_repository_impl.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_delivery.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_settings.dart';
import 'package:login_signup/features/reminders/domain/failures/reminder_failures.dart';
import 'package:login_signup/features/reminders/domain/usecases/delete_reminder_rule_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/get_reminder_deliveries_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/get_reminder_rules_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/get_reminder_settings_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/preview_reminder_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/save_reminder_rule_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/update_reminder_settings_usecase.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';

Failure? leftOf(Either<Failure, Object?> r) => r.fold((f) => f, (_) => null);
T rightOf<T>(Either<Failure, T> r) =>
    r.getOrElse(() => throw StateError('Left: ${leftOf(r)}'));

ResponseBody errorBody(int status, String code, String message) =>
    jsonBody(status, {'statusCode': status, 'code': code, 'message': message});

/// Respuesta real de `GET /reminders/settings`.
const backendSettings = {
  'enabled': true,
  'send_window_start': '08:00',
  'send_window_end': '20:00',
  'channel': 'log',
  'quota': {'limit': 10, 'used': 3, 'period': '2026-11'},
};

/// Una regla tal como la devuelve el backend.
Map<String, dynamic> backendRule({
  String id = 'r1',
  String kind = 'before_appointment',
  Object? minutes = 1440,
  Object? days,
  Object? sendTime,
  String category = 'utility',
}) =>
    {
      'id': id,
      'ownerId': 'owner-1',
      'kind': kind,
      'is_active': true,
      'minutes_before': minutes,
      'days_without_visit': days,
      'send_time': sendTime,
      'template': 'Hola {cliente}, tu cita es el {fecha} a las {hora}.',
      'category': category,
      'meta_template_name': null,
      'created_at': '2026-10-31T08:00:00.000-05:00',
      'updated_at': '2026-10-31T08:00:00.000-05:00',
    };

void main() {
  late FakeHttpClientAdapter adapter;
  late RemindersRepositoryImpl repository;

  setUp(() {
    BusinessTimeZone.use('America/Bogota');
    adapter = FakeHttpClientAdapter((_) => jsonBody(200, backendSettings));
    repository = RemindersRepositoryImpl(RemindersRemoteDataSourceImpl(
        buildApiClient(
            baseUrl: 'http://api.test/api',
            tokenStore: MemoryTokenStore('jwt'),
            httpClientAdapter: adapter,
            retryDelay: (_) => Duration.zero,
            enableLogs: false)));
  });

  tearDown(BusinessTimeZone.reset);

  group('configuración', () {
    test('GET: encendido, ventana, canal y cupo del mes', () async {
      final settings =
          rightOf(await GetReminderSettingsUseCase(repository)(NoParams()));
      expect(settings.enabled, true);
      expect(settings.isSimulated, true);
      expect(settings.quota.remaining, 7);
      expect(settings.quota.isExhausted, false);
      expect(adapter.requests.single.headers['Authorization'], 'Bearer jwt');
    });

    test('PUT solo con enabled y la ventana', () async {
      final settings = ReminderSettingsModel.fromJson(backendSettings);
      rightOf(await UpdateReminderSettingsUseCase(repository)(
          settings.copyWith(enabled: false, sendWindowEnd: '21:30')));
      final request = adapter.requests.single;
      expect(request.method, 'PUT');
      expect(request.uri.path, '/api/reminders/settings');
      expect(request.data, {
        'enabled': false,
        'send_window_start': '08:00',
        'send_window_end': '21:30',
      });
    });

    test('ventana mal escrita → failure sin red; cupo ilimitado', () async {
      expect(
          leftOf(await UpdateReminderSettingsUseCase(repository)(
              const ReminderSettings(sendWindowStart: '8:00'))),
          isA<InvalidReminderDataFailure>());
      expect(adapter.requests, isEmpty);
      const unlimited = MessageQuota(limit: -1, used: 50);
      expect(unlimited.remaining, isNull);
      expect(unlimited.isExhausted, false);
    });

    test('403 del Employee → ForbiddenFailure', () async {
      adapter.handler = (_) => errorBody(403, 'FORBIDDEN', 'Solo el dueño');
      expect(leftOf(await repository.getSettings()), isA<ForbiddenFailure>());
    });
  });

  group('reglas', () {
    test('lista: cada tipo con sus campos; send_time "10:00:00" → "10:00"',
        () async {
      adapter.handler = (_) => jsonBody(200, [
            backendRule(),
            backendRule(
                id: 'r2',
                kind: 'win_back',
                minutes: null,
                days: 60,
                sendTime: '10:00:00',
                category: 'marketing'),
          ]);
      final rules = rightOf(await GetReminderRulesUseCase(repository)(NoParams()));
      expect(rules.first.kind, ReminderKind.beforeAppointment);
      expect(rules.first.minutesBefore, 1440);
      expect(rules.last.daysWithoutVisit, 60);
      expect(rules.last.sendTime, '10:00');
      expect(rules.last.category, ReminderCategory.marketing);
    });

    test('crear: POST con kind y solo los campos de su tipo', () async {
      adapter.handler = (_) => jsonBody(201, backendRule());
      rightOf(await SaveReminderRuleUseCase(repository)(const ReminderRule(
          kind: ReminderKind.beforeAppointment,
          minutesBefore: 1440,
          sendTime: '10:00',
          template: '  ')));
      final request = adapter.requests.single;
      expect('${request.method} ${request.uri.path}', 'POST /api/reminders/rules');
      expect(request.data, {
        'kind': 'before_appointment',
        'is_active': true,
        'minutes_before': 1440,
        'category': 'utility',
      }, reason: 'sin send_time (no es de su tipo) ni plantilla vacía');
    });

    test('editar: PATCH sin kind', () async {
      adapter.handler = (_) => jsonBody(200, backendRule());
      final rule = ReminderRuleModel.fromJson(backendRule());
      rightOf(await SaveReminderRuleUseCase(repository)(
          rule.copyWith(isActive: false)));
      final request = adapter.requests.single;
      expect('${request.method} ${request.uri.path}',
          'PATCH /api/reminders/rules/r1');
      expect((request.data as Map).containsKey('kind'), false);
      expect((request.data as Map)['is_active'], false);
    });

    test('reglas locales: minutos, días, categoría y plantilla → sin red',
        () async {
      final save = SaveReminderRuleUseCase(repository);
      for (final rule in const [
        ReminderRule(kind: ReminderKind.beforeAppointment, minutesBefore: 2),
        ReminderRule(kind: ReminderKind.winBack, daysWithoutVisit: 3),
        ReminderRule(
            kind: ReminderKind.birthday, category: ReminderCategory.utility),
        ReminderRule(kind: ReminderKind.birthday, template: 'Hola {nombre}'),
        ReminderRule(kind: ReminderKind.birthday, sendTime: '25:00'),
        ReminderRule(
            kind: ReminderKind.maintenance, metaTemplateName: 'Con Mayúsculas'),
      ]) {
        expect(leftOf(await save(rule)), isA<InvalidReminderDataFailure>(),
            reason: '$rule');
      }
      expect(adapter.requests, isEmpty);
    });

    test('regla repetida (409 CONFLICT) → DuplicateReminderRuleFailure con el '
        'texto del backend', () async {
      adapter.handler = (_) => errorBody(409, 'CONFLICT',
          'Ya hay un recordatorio 1440 minutos antes de la cita');
      final failure = leftOf(await repository.saveRule(const ReminderRule(
          kind: ReminderKind.beforeAppointment, minutesBefore: 1440)));
      expect(failure, isA<DuplicateReminderRuleFailure>());
      expect(failure!.message,
          'Ya hay un recordatorio 1440 minutos antes de la cita');
    });

    test('borrar y vista previa', () async {
      adapter.handler = (_) => jsonBody(200, {'deleted': true});
      rightOf(await DeleteReminderRuleUseCase(repository)('r1'));
      expect(adapter.requests.last.uri.path, '/api/reminders/rules/r1');

      adapter.handler = (_) => jsonBody(201, {'text': 'Hola Ana, …'});
      expect(
          rightOf(await PreviewReminderUseCase(repository)(
              const PreviewReminderParams(
                  kind: ReminderKind.birthday, template: ' ¡Feliz día {cliente}! '))),
          'Hola Ana, …');
      expect(adapter.requests.last.data,
          {'kind': 'birthday', 'template': '¡Feliz día {cliente}!'});
      expect(
          leftOf(await PreviewReminderUseCase(repository)(
              const PreviewReminderParams(
                  kind: ReminderKind.birthday, template: '{otra}'))),
          isA<InvalidReminderDataFailure>());
    });
  });

  group('historial', () {
    test('GET con filtros y entregas con su estado, motivo y horas', () async {
      adapter.handler = (_) => jsonBody(200, [
            {
              'id': 'd1',
              'kind': 'before_appointment',
              'status': 'skipped',
              'reason': 'NO_CONSENT',
              'clientId': 'cli-1',
              'appointmentId': 'apt-1',
              'category': 'utility',
              'phone': '+573001234567',
              'body': 'Hola Ana',
              'attempts': 0,
              'scheduledFor': '2026-11-02T10:00:00.000-05:00',
              'sentAt': null,
              'createdAt': '2026-11-01T10:00:00.000-05:00',
            },
          ]);
      final list = rightOf(await GetReminderDeliveriesUseCase(repository)(
          const DeliveriesQuery(
              status: DeliveryStatus.skipped, clientId: 'cli-1', limit: 20)));
      final delivery = list.single;
      expect(delivery.status, DeliveryStatus.skipped);
      expect(delivery.reason, DeliveryReason.noConsent);
      expect(delivery.scheduledFor, DateTime(2026, 11, 2, 10));
      expect(adapter.requests.single.uri.queryParameters, {
        'status': 'skipped',
        'client_id': 'cli-1',
        'limit': '20',
        'offset': '0',
      });
    });

    test('página fuera de rango → failure sin red', () async {
      expect(
          leftOf(await GetReminderDeliveriesUseCase(repository)(
              const DeliveriesQuery(limit: 500))),
          isA<InvalidReminderDataFailure>());
      expect(adapter.requests, isEmpty);
    });
  });
}
