import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/repositories/settings_repository.dart';
import 'package:login_signup/features/settings/domain/usecases/get_business_settings_usecase.dart';
import 'package:login_signup/features/settings/domain/usecases/update_business_name_usecase.dart';
import 'package:login_signup/features/settings/domain/usecases/update_business_time_zone_usecase.dart';
import 'package:login_signup/features/settings/domain/usecases/update_opening_hours_usecase.dart';
import 'package:login_signup/features/settings/presentation/controllers/business_settings_controller.dart';
import 'package:login_signup/features/settings/presentation/screens/business_settings_screen.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';

import '../../core/session/jwt_helper.dart';
import '../../core/session/memory_token_store.dart';

/// Repositorio falso que, como el real, fija en la sesión la zona que
/// devuelve el backend (`SessionService.applyTimeZone`).
class FakeSettingsRepository implements SettingsRepository {
  final SessionService session;
  BusinessSettings current;
  Failure? getFailure;
  Failure? updateFailure;
  final zoneUpdates = <String>[];
  final nameUpdates = <String>[];
  final hoursUpdates = <OpeningHours?>[];

  FakeSettingsRepository(this.session,
      {this.current = const BusinessSettings(timeZone: 'America/Bogota')});

  @override
  Future<Either<Failure, BusinessSettings>> getSettings() async {
    final failure = getFailure;
    if (failure != null) return Left(failure);
    await session.applyTimeZone(current.timeZone);
    return Right(current);
  }

  @override
  Future<Either<Failure, BusinessSettings>> updateTimeZone(
      String timeZone) async {
    zoneUpdates.add(timeZone);
    final failure = updateFailure;
    if (failure != null) return Left(failure);
    current = current.copyWith(timeZone: timeZone);
    await session.applyTimeZone(timeZone);
    return Right(current);
  }

  @override
  Future<Either<Failure, BusinessSettings>> updateName(String name) async {
    nameUpdates.add(name);
    final failure = updateFailure;
    if (failure != null) return Left(failure);
    // Como el backend: el slug nace con el primer nombre y no cambia.
    current = current.copyWith(
        name: name, slug: current.slug ?? 'cejas-luna');
    return Right(current);
  }

  @override
  Future<Either<Failure, BusinessSettings>> updateOpeningHours(
      OpeningHours? hours) async {
    hoursUpdates.add(hours);
    final failure = updateFailure;
    if (failure != null) return Left(failure);
    current = hours == null
        ? current.copyWith(clearOpeningHours: true)
        : current.copyWith(openingHours: hours);
    return Right(current);
  }
}

const zones = [
  'America/Bogota',
  'America/Caracas',
  'America/New_York',
  'Europe/Madrid',
];

const nine = WorkHours(start: '09:00', end: '18:00');

void main() {
  late SessionService service;
  late SessionController session;
  late FakeSettingsRepository repo;
  late List<Uri> opened;

  setUpAll(() => initializeDateFormatting('es'));

  setUp(() async {
    Get.testMode = true;
    final tokens = MemoryTokenStore(fakeJwt({'id': 'u1', 'roles': 'Owner'}));
    service = SessionService(
      tokenStore: tokens,
      repository: SessionRepository(tokens),
      timeZoneStore: MemoryTimeZoneStore(),
    );
    session = SessionController(service);
    await service.applyTimeZone('America/Bogota');
    await session.reload();
    Get.put<SessionController>(session, permanent: true);
    repo = FakeSettingsRepository(service);
    opened = [];
  });

  tearDown(() {
    Get.reset();
    BusinessTimeZone.reset();
    BusinessTimeZone.clock = DateTime.now;
  });

  BusinessSettingsController buildController() => BusinessSettingsController(
        getBusinessSettingsUseCase: GetBusinessSettingsUseCase(repo),
        updateBusinessTimeZoneUseCase: UpdateBusinessTimeZoneUseCase(repo),
        updateBusinessNameUseCase: UpdateBusinessNameUseCase(repo),
        updateOpeningHoursUseCase: UpdateOpeningHoursUseCase(repo),
        session: session,
        zones: zones,
        apiUrl: () => 'https://api.agendity.co/api/',
        openLink: (uri) async {
          opened.add(uri);
          return true;
        },
      );

  Future<BusinessSettingsController> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = Get.put(buildController());
    await tester.pumpWidget(GetMaterialApp(
      theme: ThemeConfig.lightTheme,
      home: const BusinessSettingsScreen(),
    ));
    await tester.pumpAndSettle();
    return controller;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> expireSnackbar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  test('publicBookingLink: base del API sin /api', () {
    expect(publicBookingLink('http://localhost:3000/api', 'luna'),
        'http://localhost:3000/reservar/luna');
    expect(publicBookingLink('https://x.co/api/', 'luna'),
        'https://x.co/reservar/luna');
    expect(publicBookingLink('https://x.co', 'a b'), 'https://x.co/reservar/a%20b');
  });

  group('BusinessSettingsController', () {
    test('carga zona, nombre, link y horario', () async {
      repo.current = BusinessSettings(
        timeZone: 'America/Bogota',
        name: 'Cejas Luna',
        slug: 'cejas-luna',
        openingHours: OpeningHours(const [
          OpeningHoursRange(dayOfWeek: 1, hours: nine),
        ]),
      );
      final c = buildController()..onInit();
      await Future<void>.delayed(Duration.zero);
      expect(c.status.value, BusinessSettingsStatus.ready);
      expect(c.nameController.text, 'Cejas Luna');
      expect(c.bookingLink, 'https://api.agendity.co/reservar/cejas-luna');
      expect(c.limitsHours.value, isTrue);
      expect(c.rangesOn(1), [nine]);
      expect(c.isClosedOn(2), isTrue);
      expect(c.hoursChanged, isFalse);
      c.onClose();
    });

    test('sin horario: el borrador propone lunes a sábado y no hay cambios',
        () async {
      final c = buildController()..onInit();
      await Future<void>.delayed(Duration.zero);
      expect(c.limitsHours.value, isFalse);
      expect(c.hoursChanged, isFalse);
      expect(c.rangesOn(6), [nine]);
      expect(c.isClosedOn(7), isTrue);
      c.setLimitsHours(true);
      expect(c.hoursChanged, isTrue);
      c.onClose();
    });

    test('franjas: cerrar, abrir, añadir, editar y quitar', () async {
      final c = buildController()..onInit();
      await Future<void>.delayed(Duration.zero);
      c.setDayOpen(1, false);
      expect(c.isClosedOn(1), isTrue);
      c.setDayOpen(1, true);
      c.updateRange(1, 0, end: '13:00');
      c.addRange(1);
      expect(c.rangesOn(1), const [
        WorkHours(start: '09:00', end: '13:00'),
        WorkHours(start: '14:00', end: '18:00'),
      ]);
      c.removeRange(1, 1);
      expect(c.rangesOn(1), const [WorkHours(start: '09:00', end: '13:00')]);
      c.onClose();
    });

    test('busca sin distinguir mayúsculas y con espacio en lugar de _',
        () async {
      final c = buildController()..onInit();
      c.searchController.text = 'new york';
      expect(c.filteredZones, ['America/New_York']);
      c.clearSearch();
      expect(c.filteredZones, zones);
      c.onClose();
    });

    test('offset y hora de cada zona', () {
      BusinessTimeZone.clock = () => DateTime.utc(2030, 1, 1, 15);
      final c = buildController();
      expect(c.offsetOf('America/Bogota'), 'UTC-05:00');
      expect(c.offsetOf('America/Caracas'), 'UTC-04:00');
      expect(c.nowIn('America/Caracas'), contains('11:00'));
    });

    test('sin permiso (403): error final, sin reintento', () async {
      repo.getFailure = const ForbiddenFailure(message: 'Sin permiso');
      final c = buildController()..onInit();
      await Future<void>.delayed(Duration.zero);
      expect(c.status.value, BusinessSettingsStatus.error);
      expect(c.loadErrorIsFinal.value, isTrue);
      c.onClose();
    });
  });

  group('pantalla', () {
    testWidgets('nombre: guardar crea el link; copiar y compartir',
        (tester) async {
      final c = await pumpScreen(tester);
      expect(find.text('Mi negocio'), findsOneWidget);
      expect(find.text('Ponle nombre al negocio para tener tu link.'),
          findsOneWidget);

      await tester.enterText(find.byKey(const Key('business-name')),
          '  Cejas Luna ');
      await tap(tester, find.text('Guardar nombre'));
      expect(repo.nameUpdates, ['Cejas Luna']);
      expect(find.text('https://api.agendity.co/reservar/cejas-luna'),
          findsOneWidget);
      await expireSnackbar(tester);

      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      await tap(tester, find.text('Copiar'));
      expect(copied, c.bookingLink);
      expect(find.text('Link copiado'), findsOneWidget);
      await expireSnackbar(tester);

      await tap(tester, find.text('Compartir por WhatsApp'));
      expect(opened.single.host, 'wa.me');
      expect(opened.single.queryParameters['text'],
          'Reserva tu cita en Cejas Luna: ${c.bookingLink}');
    });

    testWidgets('nombre inválido: aviso y no se envía', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byKey(const Key('business-name')), 'L');
      await tap(tester, find.text('Guardar nombre'));
      expect(repo.nameUpdates, isEmpty);
      expect(find.textContaining('entre 2 y 100 caracteres'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('horario: activar, cerrar el sábado y guardar', (tester) async {
      await pumpScreen(tester);
      await tap(tester, find.byKey(const Key('opening-hours-enabled')));
      expect(find.text('Sábado'), findsOneWidget);
      await tap(tester, find.byKey(const Key('opening-day-6')));
      await tap(tester, find.text('Guardar horario'));

      final sent = repo.hoursUpdates.single!;
      expect(sent.isClosedOn(6), isTrue);
      expect(sent.isClosedOn(7), isTrue);
      expect(sent.rangesOn(1).single.hours, nine);
      expect(find.text('Horario guardado'), findsOneWidget);
      expect(find.text('Guardar horario'), findsNothing);
      await expireSnackbar(tester);
    });

    testWidgets('horario: quitarlo envía null', (tester) async {
      repo.current = BusinessSettings(
          timeZone: 'America/Bogota',
          openingHours: OpeningHours(const [
            OpeningHoursRange(dayOfWeek: 1, hours: nine),
          ]));
      await pumpScreen(tester);
      await tap(tester, find.byKey(const Key('opening-hours-enabled')));
      await tap(tester, find.text('Guardar horario'));
      expect(repo.hoursUpdates, [null]);
      await expireSnackbar(tester);
    });

    testWidgets('horario con franjas que se pisan: aviso y no se envía',
        (tester) async {
      final c = await pumpScreen(tester);
      c.setLimitsHours(true);
      c.addRange(1); // 19:00–23:00
      c.updateRange(1, 1, start: '17:00'); // se pisa con 09:00–18:00
      await tester.pumpAndSettle();
      await tap(tester, find.text('Guardar horario'));
      expect(repo.hoursUpdates, isEmpty);
      expect(find.textContaining('se pisan'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('zona: elegir en el selector, confirmar y avisar a quien '
        'escucha el cambio', (tester) async {
      final changes = <String>[];
      final worker = session.onTimeZoneChanged(changes.add);
      addTearDown(worker.dispose);

      await pumpScreen(tester);
      await tap(tester, find.text('Cambiar'));
      await tester.enterText(find.byType(TextField).last, 'caracas');
      await tester.pumpAndSettle();
      await tap(tester, find.text('America/Caracas'));
      expect(find.text('¿Cambiar la zona horaria?'), findsOneWidget);
      await tap(tester, find.text('Cambiar zona'));

      expect(repo.zoneUpdates, ['America/Caracas']);
      expect(session.timeZone, 'America/Caracas');
      expect(changes, ['America/Caracas']);
      expect(find.text('Zona horaria guardada'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('zona: búsqueda sin resultados y cancelar', (tester) async {
      await pumpScreen(tester);
      await tap(tester, find.text('Cambiar'));
      await tester.enterText(find.byType(TextField).last, 'marte');
      await tester.pumpAndSettle();
      expect(find.text('Ninguna zona coincide'), findsOneWidget);
      await tap(tester, find.byTooltip('Cerrar'));
      expect(repo.zoneUpdates, isEmpty);
    });

    testWidgets('error de carga con reintento', (tester) async {
      repo.getFailure = const NetworkFailure(message: 'Sin conexión');
      await pumpScreen(tester);
      expect(find.byType(ErrorState), findsOneWidget);
      repo.getFailure = null;
      await tap(tester, find.text('Reintentar'));
      expect(find.text('Zona horaria del negocio'), findsOneWidget);
    });
  });
}
