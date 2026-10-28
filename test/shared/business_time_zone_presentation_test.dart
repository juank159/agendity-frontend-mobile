import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/statistics/presentation/controllers/stats_period_controller.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_limits_usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/widgets/business_time_zone_notice.dart';

import '../core/session/jwt_helper.dart';
import '../core/session/memory_token_store.dart';

/// "Hoy" y "ahora" de la UI en la zona del negocio, no en la del
/// dispositivo (D-15). Correr también con `TZ=Asia/Tokyo`: no depende del
/// teléfono.
class _Period extends StatsPeriodController {
  @override
  void onRangeChanged() {}
}

class _AppointmentsRepo implements AppointmentsRepository {
  final ranges = <AppointmentsRange>[];

  @override
  Future<Either<Failure, List<AppointmentEntity>>> getAppointments(
      AppointmentsRange range) async {
    ranges.add(range);
    return const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SubscriptionRepo implements SubscriptionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // 2030-01-01 04:30Z: en Bogotá (UTC-5) aún es el 31 de diciembre a las
  // 23:30; en Caracas (UTC-4) ya es el 1 de enero a las 00:30; en el
  // teléfono puede ser cualquier cosa.
  final instant = DateTime.utc(2030, 1, 1, 4, 30);

  late SessionService service;
  late SessionController session;

  setUp(() async {
    Get.testMode = true;
    BusinessTimeZone.clock = () => instant;
    final tokens = MemoryTokenStore(fakeJwt({'id': 'u1', 'roles': 'Owner'}));
    service = SessionService(
      tokenStore: tokens,
      repository: SessionRepository(tokens),
      timeZoneStore: MemoryTimeZoneStore(),
    );
    session = SessionController(service);
  });

  tearDown(() {
    Get.reset();
    BusinessTimeZone.reset();
    BusinessTimeZone.clock = DateTime.now;
  });

  group('hoy del negocio', () {
    test('estadísticas: "hoy" es el día del negocio', () {
      BusinessTimeZone.use('America/Bogota');
      expect(_Period().today, DateTime(2029, 12, 31));
      BusinessTimeZone.use('America/Caracas');
      final period = _Period();
      expect(period.today, DateTime(2030, 1, 1));
      expect(period.range.value.start, DateTime(2030, 1, 1));
    });

    test('agenda: abre en el día del negocio', () {
      BusinessTimeZone.use('America/Caracas');
      final agenda = AppointmentsController(
        getAppointmentsUseCase: GetAppointmentsUseCase(_AppointmentsRepo()),
        checkSubscriptionLimitsUseCase:
            CheckSubscriptionLimitsUseCase(_SubscriptionRepo()),
      );
      expect(agenda.selectedDate.value, DateTime(2030, 1, 1, 0, 30));
    });
  });

  group('cambio de zona', () {
    test('SessionController.timeZone sigue a la sesión', () async {
      expect(session.timeZone, BusinessTimeZone.fallback);
      await service.applyTimeZone('America/Caracas');
      await session.reload();
      expect(session.timeZone, 'America/Caracas');
    });

    test('la agenda vuelve a pedir sus citas; cerrar sesión no', () async {
      await service.applyTimeZone('America/Bogota');
      await session.reload();
      Get.put<SessionController>(session, permanent: true);
      final repo = _AppointmentsRepo();
      final agenda = AppointmentsController(
        getAppointmentsUseCase: GetAppointmentsUseCase(repo),
        checkSubscriptionLimitsUseCase:
            CheckSubscriptionLimitsUseCase(_SubscriptionRepo()),
      )..onInit();
      await Future<void>.delayed(Duration.zero);
      expect(repo.ranges, hasLength(1));

      await service.applyTimeZone('America/Caracas');
      await session.reload();
      await Future<void>.delayed(Duration.zero);
      expect(repo.ranges, hasLength(2));

      await session.reload(); // misma zona: nada
      session.clear(); // cierre de sesión: nada
      await Future<void>.delayed(Duration.zero);
      expect(repo.ranges, hasLength(2));
      agenda.onClose();
    });
  });

  test('formatUtcOffset', () {
    expect(formatUtcOffset(const Duration(hours: -5)), 'UTC-05:00');
    expect(formatUtcOffset(const Duration(hours: 5, minutes: 30)),
        'UTC+05:30');
    expect(formatUtcOffset(Duration.zero), 'UTC');
  });

  group('BusinessTimeZoneNotice', () {
    Future<void> pump(WidgetTester tester) => tester.pumpWidget(MaterialApp(
          theme: ThemeConfig.lightTheme,
          home: const Scaffold(body: BusinessTimeZoneNotice()),
        ));

    testWidgets('se ve si el dispositivo está en otra zona', (tester) async {
      final device = instant.toLocal().timeZoneOffset;
      final zone = device == const Duration(hours: 14)
          ? 'America/Bogota'
          : 'Pacific/Kiritimati';
      BusinessTimeZone.use(zone);
      await pump(tester);
      expect(find.text(BusinessTimeZoneNotice.describe(zone)), findsOneWidget);
    });

    testWidgets('no ocupa espacio si coinciden', (tester) async {
      final device = instant.toLocal().timeZoneOffset;
      if (device.inMinutes % 60 != 0) return; // sin zona Etc equivalente
      final hours = device.inHours;
      // Etc/GMT invierte el signo: UTC-5 = Etc/GMT+5.
      final zone = hours == 0
          ? 'UTC'
          : 'Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}';
      BusinessTimeZone.use(zone);
      expect(BusinessTimeZone.differsFromDevice, isFalse);
      await pump(tester);
      expect(find.byIcon(Icons.public), findsNothing);
    });
  });
}
