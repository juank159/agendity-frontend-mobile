import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/repositories/settings_repository.dart';
import 'package:login_signup/features/settings/domain/usecases/get_business_settings_usecase.dart';
import 'package:login_signup/features/settings/domain/usecases/update_business_time_zone_usecase.dart';
import 'package:login_signup/features/settings/presentation/controllers/business_settings_controller.dart';
import 'package:login_signup/features/settings/presentation/screens/business_settings_screen.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';

import '../../core/session/jwt_helper.dart';
import '../../core/session/memory_token_store.dart';

/// Repositorio falso que, como el real, fija en la sesión la zona que
/// devuelve el backend (`SessionService.applyTimeZone`).
class FakeSettingsRepository implements SettingsRepository {
  final SessionService session;
  String saved;
  Failure? getFailure;
  Failure? updateFailure;
  final updates = <String>[];

  FakeSettingsRepository(this.session, {this.saved = 'America/Bogota'});

  @override
  Future<Either<Failure, BusinessSettings>> getSettings() async {
    final failure = getFailure;
    if (failure != null) return Left(failure);
    await session.applyTimeZone(saved);
    return Right(BusinessSettings(timeZone: saved));
  }

  @override
  Future<Either<Failure, BusinessSettings>> updateTimeZone(
      String timeZone) async {
    updates.add(timeZone);
    final failure = updateFailure;
    if (failure != null) return Left(failure);
    saved = timeZone;
    await session.applyTimeZone(timeZone);
    return Right(BusinessSettings(timeZone: timeZone));
  }
  // 8.03 (FD): nombre y horario; esta pantalla aún no los usa.
  @override
  Future<Either<Failure, BusinessSettings>> updateName(String name) async =>
      Right(BusinessSettings(timeZone: saved, name: name));

  @override
  Future<Either<Failure, BusinessSettings>> updateOpeningHours(
          OpeningHours? hours) async =>
      Right(BusinessSettings(timeZone: saved, openingHours: hours));
}

const zones = [
  'America/Bogota',
  'America/Caracas',
  'America/New_York',
  'Europe/Madrid',
];

void main() {
  late SessionService service;
  late SessionController session;
  late FakeSettingsRepository repo;

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
  });

  tearDown(() {
    Get.reset();
    BusinessTimeZone.reset();
    BusinessTimeZone.clock = DateTime.now;
  });

  BusinessSettingsController buildController() => BusinessSettingsController(
        getBusinessSettingsUseCase: GetBusinessSettingsUseCase(repo),
        updateBusinessTimeZoneUseCase: UpdateBusinessTimeZoneUseCase(repo),
        session: session,
        zones: zones,
      );

  Future<BusinessSettingsController> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
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

  Future<void> expireSnackbar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  group('BusinessSettingsController', () {
    test('carga la zona guardada y la marca elegida', () async {
      final c = buildController()..onInit();
      await Future<void>.delayed(Duration.zero);
      expect(c.status.value, BusinessSettingsStatus.ready);
      expect(c.savedZone.value, 'America/Bogota');
      expect(c.selectedZone.value, 'America/Bogota');
      expect(c.hasChanges, isFalse);
      c.onClose();
    });

    test('busca sin distinguir mayúsculas y con espacio en lugar de _',
        () async {
      final c = buildController()..onInit();
      c.searchController.text = 'new york';
      expect(c.filteredZones, ['America/New_York']);
      c.searchController.text = 'AMERICA';
      expect(c.filteredZones,
          ['America/Bogota', 'America/Caracas', 'America/New_York']);
      c.clearSearch();
      expect(c.filteredZones, zones);
      c.onClose();
    });

    test('offset y hora de cada zona', () {
      // 2030-01-01 15:00Z = 10:00 en Bogotá = 11:00 en Caracas.
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
    testWidgets('guardar otra zona: confirma, recarga la sesión y avisa '
        'a quien escucha el cambio', (tester) async {
      final changes = <String>[];
      final worker = session.onTimeZoneChanged(changes.add);
      addTearDown(worker.dispose);

      final c = await pumpScreen(tester);
      expect(find.text('Zona horaria del negocio'), findsOneWidget);
      expect(find.text('Sin cambios'), findsOneWidget);

      await tester.tap(find.text('America/Caracas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar America/Caracas'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cambiar la zona horaria?'), findsOneWidget);
      await tester.tap(find.text('Cambiar zona'));
      await tester.pumpAndSettle();

      expect(repo.updates, ['America/Caracas']);
      expect(c.savedZone.value, 'America/Caracas');
      expect(session.timeZone, 'America/Caracas');
      expect(BusinessTimeZone.current, 'America/Caracas');
      expect(changes, ['America/Caracas']);
      expect(find.text('Zona horaria guardada'), findsOneWidget);
      expect(find.text('Sin cambios'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('cancelar la confirmación no guarda', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Europe/Madrid'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar Europe/Madrid'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repo.updates, isEmpty);
      expect(session.timeZone, 'America/Bogota');
    });

    testWidgets('un error al guardar se avisa y la zona no cambia',
        (tester) async {
      repo.updateFailure = const ServerFailure(message: 'Falló el servidor');
      final c = await pumpScreen(tester);
      await tester.tap(find.text('America/Caracas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar America/Caracas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiar zona'));
      await tester.pumpAndSettle();

      expect(find.text('Falló el servidor'), findsOneWidget);
      expect(c.savedZone.value, 'America/Bogota');
      expect(c.hasChanges, isTrue);
      expect(session.timeZone, 'America/Bogota');
      await expireSnackbar(tester);
    });

    testWidgets('búsqueda sin resultados muestra el estado vacío',
        (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'marte');
      await tester.pumpAndSettle();
      expect(find.text('Ninguna zona coincide'), findsOneWidget);
      await tester.tap(find.byTooltip('Borrar búsqueda'));
      await tester.pumpAndSettle();
      expect(find.text('Europe/Madrid'), findsOneWidget);
    });

    testWidgets('error de carga con reintento', (tester) async {
      repo.getFailure = const NetworkFailure(message: 'Sin conexión');
      await pumpScreen(tester);
      expect(find.byType(ErrorState), findsOneWidget);
      repo.getFailure = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Zona horaria del negocio'), findsOneWidget);
    });
  });
}
