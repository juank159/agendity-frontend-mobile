import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/core/sync/sync_models.dart';
import 'package:login_signup/features/clients/data/datasources/clients_local_datasource.dart';
import 'package:login_signup/features/clients/data/sync/clients_sync_handler.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';
import 'package:login_signup/shared/custom_drawer.dart';
import 'package:login_signup/shared/screens/sync_pending_screen.dart';
import 'package:login_signup/shared/widgets/sync_entry_text.dart';
import 'package:login_signup/shared/widgets/sync_status_indicator.dart';

import '../core/sync/fake_sync_api.dart';

/// Estado de la sincronización en la UI (10.03): indicador, "Pendientes"
/// (reintentar y descartar con confirmación), primer plano y cierre de
/// sesión con cambios sin enviar.
void main() {
  late LocalDatabaseHolder databases;
  late FakeSyncServer server;
  late SyncEngine engine;
  late OfflineStore store;
  late AppDatabase db;
  late SyncController sync;
  const local = ClientsLocalDataSource();
  var ids = 0;

  setUpAll(() => initializeDateFormatting('es'));

  setUp(() async {
    Get.testMode = true;
    databases = memoryDatabases();
    server = FakeSyncServer();
    engine = SyncEngine(
        databases: databases,
        api: server,
        handlers: [ClientsSyncHandler(local)]);
    ids = 0;
    store = OfflineStore(
      databases: databases,
      clock: () => DateTime.utc(2026, 10, 31, 12),
      newId: () => 'id-${++ids}',
    );
    db = await databases.require();
    sync = SyncController(engine);
  });

  tearDown(() async {
    Get.reset();
    await engine.dispose();
    await databases.close();
  });

  Future<void> createClient(String name, String phone) =>
      store.write((db, sink) async {
        final payload = {'name': name, 'lastname': 'Ruiz', 'phone': phone};
        final id = 'c-${++ids}';
        await local.upsertFields(db, id, payload);
        await sink.add(
            type: 'client.create',
            entity: 'clients',
            entityId: id,
            payload: payload);
      });

  MutationResult Function(String) rejected(String code, String message) =>
      (id) => MutationResult(
          mutationId: id,
          status: MutationStatus.rejected,
          code: code,
          message: message);

  group('SyncController', () {
    test('rechazada: requiere atención; reintentar la sube', () async {
      sync.onInit();
      server.forced['client.create'] =
          rejected('VALIDATION_ERROR', 'El teléfono no es válido');
      await createClient('Ana', '3001112233');
      await engine.syncNow();
      await sync.loadEntries();
      expect(sync.needsAttention, 1);
      expect(sync.attentionEntries.single.code, 'VALIDATION_ERROR');

      server.forced.clear();
      await sync.retry(sync.attentionEntries.single);
      await engine.syncNow();
      await sync.loadEntries();
      expect(sync.needsAttention, 0);
      expect(sync.entries, isEmpty);
      expect(server.clients, hasLength(1));
      sync.onClose();
    });

    test('descartar la saca de la bandeja y avisa a las pantallas', () async {
      sync.onInit();
      server.forced['client.create'] = rejected('FORBIDDEN', 'Sin permiso');
      await createClient('Ana', '3001112233');
      await engine.syncNow();
      await sync.loadEntries();
      final version = sync.dataVersion.value;

      await sync.discard(sync.attentionEntries.single);
      expect(sync.entries, isEmpty);
      expect(await OutboxStore.all(db), isEmpty);
      expect(sync.dataVersion.value, greaterThan(version));
      sync.onClose();
    });

    test('sin red: pendiente y "sin conexión"; al volver, sube', () async {
      sync.onInit();
      server.offline = true;
      await createClient('Ana', '3001112233');
      await engine.syncNow();
      await Future<void>.delayed(Duration.zero);
      expect(sync.isOffline, isTrue);
      expect(sync.pending, 1);
      expect(sync.unsent, 1);

      server.offline = false;
      // Volver a primer plano pide una sincronización inmediata.
      sync.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await engine.syncNow();
      await Future<void>.delayed(Duration.zero);
      expect(sync.isOffline, isFalse);
      expect(sync.pending, 0);
      expect(server.clients, hasLength(1));
      sync.onClose();
    });
  });

  group('SyncEntryText', () {
    OutboxEntry entry(String type,
            {OutboxStatus status = OutboxStatus.rejected,
            String? code,
            String? message,
            Map<String, dynamic> payload = const {}}) =>
        OutboxEntry(
          seq: 1,
          mutationId: 'm1',
          type: type,
          entity: 'x',
          payload: payload,
          clientTime: '2026-10-31T12:00:00Z',
          status: status,
          code: code,
          message: message,
        );

    test('qué es, sobre qué y por qué, sin códigos', () {
      final e = entry('client.create',
          code: 'VALIDATION_ERROR',
          message: 'El teléfono no es válido',
          payload: {'name': 'Ana', 'lastname': 'Ruiz'});
      expect(SyncEntryText.action(e), 'Cliente nuevo');
      expect(SyncEntryText.detail(e), 'Ana Ruiz');
      expect(SyncEntryText.reason(e),
          'El servidor no aceptó los datos: El teléfono no es válido');
      expect(
          SyncEntryText.reason(entry('appointment.cancel', code: 'NOT_FOUND')),
          contains('alguien lo borró'));
      expect(SyncEntryText.discardWarning(e), contains('No se puede deshacer'));
    });

    test('plan o prueba: se reenvía sola (sin "Reintentar")', () {
      final e = entry('appointment.create', code: 'TRIAL_LIMIT_REACHED');
      expect(SyncEntryText.retriesBySelf(e), isTrue);
      expect(SyncEntryText.reason(e), contains('Compra un plan'));
    });
  });

  test('cerrar sesión con cambios sin enviar: dice que no se pierden', () {
    expect(
        CustomDrawer.logoutMessage(0), '¿Seguro que quieres cerrar la sesión?');
    final message = CustomDrawer.logoutMessage(3);
    expect(message, contains('3 cambios sin enviar'));
    expect(message, contains('No se pierden'));
  });

  group('pantallas', () {
    Future<void> pumpApp(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Get.put<SyncController>(sync, permanent: true);
      await tester.pumpWidget(GetMaterialApp(
        theme: ThemeConfig.lightTheme,
        home: home,
        getPages: [
          GetPage(
              name: GetRoutes.syncPending,
              page: () => const SyncPendingScreen()),
        ],
      ));
      await tester.pump();
    }

    testWidgets('indicador: sin conexión, pendientes y atención',
        (tester) async {
      await pumpApp(tester,
          Scaffold(appBar: AppBar(actions: const [SyncStatusIndicator()])));
      expect(find.byTooltip('Todo sincronizado'), findsOneWidget);

      sync.status.value = const SyncStatus(online: false, pending: 2);
      await tester.pump();
      expect(find.byTooltip('Sin conexión · 2 pendientes'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      sync.status.value = const SyncStatus(pending: 1, needsAttention: 1);
      await tester.pump();
      expect(find.byTooltip('1 cambios requieren atención'), findsOneWidget);
      expect(find.byIcon(Icons.sync_problem_rounded), findsOneWidget);
    });

    testWidgets('Pendientes: descartar pide confirmación y explica la pérdida',
        (tester) async {
      await tester.runAsync(() async {
        server.forced['client.create'] =
            rejected('VALIDATION_ERROR', 'El teléfono no es válido');
        await createClient('Ana', '3001112233');
        await engine.syncNow();
      });
      await pumpApp(tester, const SyncPendingScreen());
      await tester.runAsync(sync.loadEntries);
      await tester.pump();

      expect(find.text('Requieren atención'), findsOneWidget);
      expect(find.text('Cliente nuevo'), findsOneWidget);
      // Rechazada: "Descartar" y "Reintentar"; sin el "Sincronizar" de la
      // tarjeta (solo el de la cabecera).
      expect(find.text('Reintentar'), findsOneWidget);
      expect(
          find.widgetWithText(TextButton, 'Sincronizar ahora'), findsNothing);
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.textContaining('El teléfono no es válido'), findsOneWidget);

      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar este cambio?'), findsOneWidget);
      expect(find.textContaining('No se puede deshacer'), findsOneWidget);

      // "Conservar" no toca nada.
      await tester.tap(find.text('Conservar'));
      await tester.pumpAndSettle();
      expect(sync.attentionEntries, hasLength(1));

      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'Descartar'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      expect(sync.entries, isEmpty);
      expect(find.text('Todo está en el servidor'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('Pendiente sin respuesta: sin "Descartar"; "Sincronizar ahora"',
        (tester) async {
      await tester.runAsync(() async {
        server.offline = true;
        await createClient('Ana', '3001112233');
        await engine.syncNow();
      });
      await pumpApp(tester, const SyncPendingScreen());
      await tester.runAsync(sync.loadEntries);
      await tester.pump();

      expect(find.text('Esperando envío'), findsOneWidget);
      expect(find.text('Cliente nuevo'), findsOneWidget);
      expect(find.text('Descartar'), findsNothing);
      expect(find.text('Reintentar'), findsNothing);
      final cardSync = find.widgetWithText(TextButton, 'Sincronizar ahora');
      expect(cardSync, findsOneWidget);

      server.offline = false;
      await tester.runAsync(() async {
        await tester.tap(cardSync);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await sync.loadEntries();
      });
      await tester.pump();
      expect(sync.entries, isEmpty);
      expect(server.clients, hasLength(1));
      expect(find.text('Todo está en el servidor'), findsOneWidget);
    });
  });

  MutationResult Function(String) conflict(String code, String message) =>
      (id) => MutationResult(
          mutationId: id,
          status: MutationStatus.conflict,
          code: code,
          message: message);

  group('aviso de lo rechazado (7.05b)', () {
    test('avisa una vez por operación; reintentar y volver a fallar, otra vez',
        () async {
      final notices = <List<String>>[];
      final announcing = SyncController(engine,
          announce: (fresh) =>
              notices.add([for (final e in fresh) e.mutationId]));
      announcing.onInit();
      server.forced['client.create'] = conflict('CONFLICT', 'Ya existe');
      await createClient('Ana', '3001112233');
      await engine.syncNow();
      await announcing.loadEntries();
      expect(notices, hasLength(1));
      expect(notices.single, [announcing.attentionEntries.single.mutationId]);

      // Otra sincronización con el mismo conflicto: sin aviso nuevo.
      await engine.syncNow();
      await announcing.loadEntries();
      await announcing.loadEntries();
      expect(notices, hasLength(1));

      // Reintentar = mutación nueva; si el servidor la rechaza, se avisa.
      server.forced['client.create'] =
          rejected('VALIDATION_ERROR', 'El teléfono no es válido');
      await announcing.retry(announcing.attentionEntries.single);
      await engine.syncNow();
      await announcing.loadEntries();
      expect(notices, hasLength(2));
      expect(notices.last, [announcing.attentionEntries.single.mutationId]);
      announcing.onClose();
    });

    test('lo pendiente (sin respuesta) no avisa', () async {
      var notices = 0;
      final announcing = SyncController(engine, announce: (_) => notices++);
      announcing.onInit();
      server.offline = true;
      await createClient('Ana', '3001112233');
      await engine.syncNow();
      await announcing.loadEntries();
      expect(announcing.pendingEntries, hasLength(1));
      expect(notices, 0);
      announcing.onClose();
    });

    test('texto: qué cambio y dónde corregirlo', () {
      OutboxEntry entry(String id) => OutboxEntry(
            seq: 1,
            mutationId: id,
            type: 'service.create',
            entity: 'services',
            payload: const {'name': 'Corte'},
            clientTime: '2026-10-31T12:00:00Z',
            status: OutboxStatus.conflict,
          );
      final one = SyncController.attentionMessage([entry('a')]);
      expect(one, startsWith('Servicio nuevo'));
      expect(one, contains('no se guardó en el servidor'));
      expect(one, contains('Pendientes'));
      expect(SyncController.attentionMessage([entry('a'), entry('b')]),
          startsWith('2 cambios'));
    });

    testWidgets(
        'al terminar la sincronización, aviso con "Revisar" que abre '
        'Pendientes', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Get.put<SyncController>(sync, permanent: true);
      await tester.pumpWidget(GetMaterialApp(
        theme: ThemeConfig.lightTheme,
        initialRoute: '/services-test',
        getPages: [
          GetPage(
              name: '/services-test',
              page: () => const Scaffold(body: Text('Servicios'))),
          GetPage(
              name: GetRoutes.syncPending,
              page: () => const SyncPendingScreen()),
        ],
      ));
      await tester.pump();

      await tester.runAsync(() async {
        server.forced['client.create'] = conflict('CONFLICT', 'Ya existe');
        await createClient('Ana', '3001112233');
        await engine.syncNow();
        await sync.loadEntries();
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Cambio no guardado'), findsOneWidget);
      expect(find.textContaining('Cliente nuevo (Ana Ruiz)'), findsOneWidget);
      await tester.tap(find.text('Revisar'));
      await tester.pumpAndSettle();
      expect(find.byType(SyncPendingScreen), findsOneWidget);
      expect(find.text('Requieren atención'), findsOneWidget);

      // Ya en Pendientes, una lectura más no repite el aviso.
      await tester.runAsync(sync.loadEntries);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Cambio no guardado'), findsNothing);
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
    });
  });

  test('descartar una pendiente no hace nada (sin respuesta del servidor)',
      () async {
    sync.onInit();
    server.offline = true;
    await createClient('Ana', '3001112233');
    await engine.syncNow();
    await sync.loadEntries();
    expect(await sync.discard(sync.pendingEntries.single), isFalse);
    expect(sync.pendingEntries, hasLength(1));
    sync.onClose();
  });
}
