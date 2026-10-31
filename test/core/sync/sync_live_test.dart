import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/network/interceptors/auth_interceptor.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/sync/document_sync_handler.dart';
import 'package:login_signup/core/sync/sync_models.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:login_signup/features/appointments/data/sync/appointments_sync.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';
import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/data/repositories/employees_repository_impl.dart';
import 'package:login_signup/features/employees/data/sync/employees_sync.dart';
import 'package:login_signup/features/notifications/data/models/app_notification_model.dart';
import 'package:login_signup/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:login_signup/features/payments/data/sync/payments_sync.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/services/data/repositories/services_repository_impl.dart';
import 'package:login_signup/features/services/data/datasources/catalog_local_datasource.dart';
import 'package:login_signup/features/services/data/sync/catalog_sync.dart';
import 'package:login_signup/features/statistics/data/datasources/statistics_remote_datasource.dart';
import 'package:login_signup/features/statistics/data/local/statistics_local_datasource.dart';
import 'package:login_signup/features/statistics/data/models/commission_settlement_model.dart';
import 'package:login_signup/features/statistics/data/models/employee_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/payment_comparison_model.dart';
import 'package:login_signup/features/statistics/data/models/payment_method_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/payment_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/professional_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/service_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/top_client_model.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/entities/top_client_entity.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_api.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/features/clients/data/datasources/clients_local_datasource.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/clients/data/repositories/client_repository_impl.dart';
import 'package:login_signup/features/clients/data/sync/clients_sync_handler.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';

import '../session/memory_token_store.dart';
import 'fake_sync_api.dart';

/// Contrato real de `/sync` con clientes (10.02a). Solo corre con un backend
/// sobre una **copia** de `agendity_demo` (escribe):
///
///   SYNC_E2E_URL=http://127.0.0.1:3995/api flutter test test/core/sync/sync_live_test.dart
void main() {
  final url = Platform.environment['SYNC_E2E_URL'];

  test('clientes: alta sin red, subida, fusión por teléfono y bajada',
      () async {
    final tokens = MemoryTokenStore();
    final dio = buildApiClient(
        baseUrl: url!, tokenStore: tokens, enableLogs: false);
    final login = await dio.post<Map<String, dynamic>>('/auth/login',
        data: {'email': 'marcela.rojas@example.com', 'password': 'Clave@2026a'},
        options: Options(extra: {AuthInterceptor.publicKey: true}));
    tokens.token = login.data!['token'] as String;

    final databases = memoryDatabases();
    final engine = SyncEngine(
      databases: databases,
      api: DioSyncApi(dio),
      handlers: [
        ClientsSyncHandler(
            const ClientsLocalDataSource(), ClientsRemoteDataSourceImpl(dio)),
      ],
    );
    final repository = ClientsRepositoryImpl(
      remote: ClientsRemoteDataSourceImpl(dio),
      store: OfflineStore(databases: databases),
    );
    final db = await databases.require();

    // Carga inicial.
    await engine.syncNow();
    expect(engine.current.lastError, isNull);
    final before =
        (await repository.getClients(const ClientsQuery(limit: 100)))
            .getOrElse(() => throw StateError('lectura'));
    expect(before.total, greaterThan(0));
    final existing = before.items.first;

    // Alta nueva y alta con un teléfono que ya existe (fusión).
    final suffix = DateTime.now().millisecondsSinceEpoch % 10000000;
    final created = (await repository.createClient(ClientEntity(
            name: 'Offline', lastname: 'Prueba', phone: '311$suffix'.padRight(10, '0'))))
        .getOrElse(() => throw StateError('alta'));
    final duplicateId = 'ffffffff-0000-7000-8000-${suffix.toString().padLeft(12, '0')}';
    await OfflineStore(databases: databases, newId: () => duplicateId)
        .write((db, sink) async {
      final payload = {'name': 'Dup', 'lastname': '', 'phone': existing.phone};
      await const ClientsLocalDataSource().upsertFields(db, duplicateId, payload);
      await sink.add(
          type: 'client.create',
          entity: 'clients',
          entityId: duplicateId,
          payload: payload);
    });
    final edited = (await repository.updateClient(
            created.copyWith(notes: 'Creado sin red')))
        .getOrElse(() => throw StateError('edición'));

    await engine.syncNow();
    expect(engine.current.lastError, isNull);
    expect(await OutboxStore.all(db), isEmpty);

    // Lo creado llegó con la forma del servidor.
    final synced = (await repository.getClientById(edited.id!))
        .getOrElse(() => throw StateError('leer'));
    expect(synced.notes, 'Creado sin red');
    expect(synced.createdAt, isNotNull);
    // El duplicado se fusionó con el existente.
    expect((await repository.getClientById(duplicateId))
            .getOrElse(() => throw StateError('alias'))
            .id,
        existing.id);

    // Borrado sube y la bajada lo confirma.
    await repository.deleteClient(created.id!);
    await engine.syncNow();
    expect(await OutboxStore.all(db), isEmpty);
    expect((await repository.getClientById(created.id!)).isLeft(), true);
    await engine.dispose();
    await databases.close();
  }, skip: url == null ? 'Solo con SYNC_E2E_URL' : null);

  test('10.02b: catálogo, cita, pago e importación sin red contra el '
      'servidor real', () async {
    final tokens = MemoryTokenStore();
    final dio = buildApiClient(
        baseUrl: url!, tokenStore: tokens, enableLogs: false);
    final login = await dio.post<Map<String, dynamic>>('/auth/login',
        data: {'email': 'marcela.rojas@example.com', 'password': 'Clave@2026a'},
        options: Options(extra: {AuthInterceptor.publicKey: true}));
    tokens.token = login.data!['token'] as String;

    final databases = memoryDatabases();
    final engine = SyncEngine(
      databases: databases,
      api: DioSyncApi(dio),
      handlers: [
        ClientsSyncHandler(
            const ClientsLocalDataSource(), ClientsRemoteDataSourceImpl(dio)),
        ...CatalogSync.handlers(),
        ...EmployeesSync.handlers(),
        ...AppointmentsSync.handlers(),
        ...PaymentsSync.handlers(),
        DocumentSyncHandler(SharedDocs.businessSettings),
        DocumentSyncHandler(AppNotificationModel.kind),
      ],
    );
    final store = OfflineStore(databases: databases);
    final db = await databases.require();
    await engine.syncNow();
    expect(engine.current.lastError, isNull);

    // Todo lo del negocio bajó.
    final settings =
        (await DocumentStore.list(db, SharedDocs.businessSettings.entity))
            .single;
    BusinessTimeZone.use(settings['timezone'] as String);
    addTearDown(BusinessTimeZone.reset);
    final employees = (await EmployeesRepositoryImpl(
                EmployeesRemoteDataSourceImpl(dio),
                store: store,
                refresh: engine.syncNow)
            .getEmployees())
        .getOrElse(() => throw StateError('empleados'));
    expect(employees, isNotEmpty);
    final services = ServicesRepositoryImpl(store);
    final pro = employees.firstWhere((e) => !e.isOwner && e.isActive);
    final offered = (await services.getServicesOfferedBy(pro.id))
        .getOrElse(() => throw StateError('servicios'));
    expect(offered, isNotEmpty);

    // Sin red: servicio nuevo, cita con un servicio de la profesional, pago e
    // importación de un contacto.
    final suffix = DateTime.now().millisecondsSinceEpoch % 1000000;
    final service = (await services.createService(ServiceEntity(
            name: 'Offline $suffix',
            price: 10000,
            duration: 30,
            categoryId: offered.first.categoryId)))
        .getOrElse(() => throw StateError('servicio'));
    final clients = ClientsRepositoryImpl(
        remote: ClientsRemoteDataSourceImpl(dio), store: store);
    final client = (await clients.getClients(const ClientsQuery()))
        .getOrElse(() => throw StateError('clientes'))
        .items
        .first;
    final appointments = AppointmentsRepositoryImpl(
        AppointmentsRemoteDataSourceImpl(dio),
        store: store);
    final day = BusinessTimeZone.today().add(Duration(days: 20 + suffix % 30));
    final created = (await appointments.createAppointment(NewAppointment(
            clientId: client.id!,
            professionalId: pro.id,
            serviceIds: [offered.first.id!],
            start: DateTime(day.year, day.month, day.day, 10))))
        .getOrElse(() => throw StateError('cita'));
    final payment = (await PaymentRepositoryImpl(store).createPayment(
            PaymentEntity(
                appointmentId: created.id,
                amount: 1000,
                paymentMethod: PaymentMethod.CASH)))
        .getOrElse(() => throw StateError('pago'));
    final imported = await clients.importClients([
      ClientEntity(name: 'Contacto', phone: '312${suffix.toString().padLeft(7, '0')}'),
    ]);
    expect(imported.isRight(), true);

    await engine.syncNow();
    expect(engine.current.lastError, isNull);
    expect(await OutboxStore.all(db), isEmpty,
        reason: 'cada mutación tuvo resultado');

    // Lo que dice el servidor, ya en local.
    final synced = (await appointments.getAppointment(created.id))
        .getOrElse(() => throw StateError('cita sincronizada'));
    expect(synced.services.single.serviceId, offered.first.id);
    // Con hueco: confirmada por el pago; sin hueco: guardada para mover.
    expect(synced.needsReschedule || synced.isConfirmed, true);
    final payments = (await PaymentRepositoryImpl(store)
            .getAppointmentPayments(created.id))
        .getOrElse(() => []);
    expect(payments.map((p) => p.id), contains(payment.id));
    expect(
        (await services.getAllServices())
            .getOrElse(() => [])
            .map((s) => s.id),
        contains(service.id));
    final importedClients = (await clients.getClients(
            const ClientsQuery(source: ClientSourceFilter.imported)))
        .getOrElse(() => throw StateError('importados'));
    expect(importedClients.items.map((c) => c.name), contains('Contacto'));
    await engine.dispose();
    await databases.close();
  }, skip: url == null ? 'Solo con SYNC_E2E_URL' : null);

  test('10.02c: estadísticas locales = las del servidor sobre los mismos '
      'datos', () async {
    final tokens = MemoryTokenStore();
    final dio = buildApiClient(
        baseUrl: url!, tokenStore: tokens, enableLogs: false);
    final login = await dio.post<Map<String, dynamic>>('/auth/login',
        data: {'email': 'marcela.rojas@example.com', 'password': 'Clave@2026a'},
        options: Options(extra: {AuthInterceptor.publicKey: true}));
    tokens.token = login.data!['token'] as String;
    final databases = memoryDatabases();
    final engine = SyncEngine(
      databases: databases,
      api: DioSyncApi(dio),
      handlers: [
        ClientsSyncHandler(const ClientsLocalDataSource()),
        ...CatalogSync.handlers(),
        ...EmployeesSync.handlers(),
        ...AppointmentsSync.handlers(),
        ...PaymentsSync.handlers(),
        DocumentSyncHandler(SharedDocs.businessSettings),
      ],
    );
    await engine.syncNow();
    final db = await databases.require();
    final settings =
        (await DocumentStore.list(db, SharedDocs.businessSettings.entity))
            .single;
    BusinessTimeZone.use(settings['timezone'] as String);
    addTearDown(BusinessTimeZone.reset);

    final remote = StatisticsRemoteDataSourceImpl(dio);
    final local = await const StatisticsLocalDataSource().load(db);
    final from = DateTime(2026, 10, 1);
    final to = DateTime(2026, 12, 31);
    final range = StatsRange(start: from, end: to);

    expect(PaymentStatsModel.fromJson(local.paymentStats(from, to)).toEntity(),
        (await remote.getPaymentStats(range)).toEntity());
    expect(
        PaymentComparisonModel.fromJson(local.comparison(from, to)).toEntity(),
        (await remote.getPaymentComparison(range)).toEntity());
    expect([
      for (final r in local.byMethod(from, to))
        PaymentMethodStatsModel.fromJson(r).toEntity()
    ], [
      for (final m in await remote.getPaymentStatsByMethod(range)) m.toEntity()
    ]);
    expect([
      for (final r in local.byService(from, to))
        ServiceStatsModel.fromJson(r).toEntity()
    ], [
      for (final m in await remote.getPaymentStatsByService(range)) m.toEntity()
    ]);
    expect([
      for (final r in local.byProfessional(from, to))
        ProfessionalStatsModel.fromJson(r).toEntity()
    ], [
      for (final m in await remote.getPaymentStatsByProfessional(range))
        m.toEntity()
    ]);
    // Mejores clientes: el SQL no desempata (empates en otro orden), así que
    // se comparan todos, ordenados igual.
    int byTotalThenId(TopClientEntity a, TopClientEntity b) {
      final byTotal = b.totalSpent.compareTo(a.totalSpent);
      return byTotal != 0 ? byTotal : a.clientId.compareTo(b.clientId);
    }
    expect([
      for (final r in local.topClients(from, to, limit: 1000))
        TopClientModel.fromJson(r).toEntity()
    ]..sort(byTotalThenId), [
      for (final m in await remote.getTopClients(range, limit: 1000))
        m.toEntity()
    ]..sort(byTotalThenId));
    final pro = (await remote.getPaymentStatsByProfessional(range))
        .first
        .toEntity()
        .professionalId;
    expect(
        EmployeeStatsModel.fromJson(local.employeeStats(from, to, pro))
            .toEntity(),
        (await remote.getEmployeeStats(range, professionalId: pro))
            .toEntity());
    expect(CommissionSettlementModel.fromJson(local.commissions(from, to)),
        await remote.getCommissionSettlement(range));
    await engine.dispose();
    await databases.close();
  }, skip: url == null ? 'Solo con SYNC_E2E_URL' : null);

  test('base restaurada (npm run sync:new-epoch sobre la copia): la app rehace '
      'la bajada sin perder la bandeja', () async {
    final backendDir = Platform.environment['SYNC_E2E_BACKEND_DIR']!;
    final dbName = Platform.environment['SYNC_E2E_DB']!;
    final tokens = MemoryTokenStore();
    final dio = buildApiClient(
        baseUrl: url!, tokenStore: tokens, enableLogs: false);
    final login = await dio.post<Map<String, dynamic>>('/auth/login',
        data: {'email': 'marcela.rojas@example.com', 'password': 'Clave@2026a'},
        options: Options(extra: {AuthInterceptor.publicKey: true}));
    tokens.token = login.data!['token'] as String;
    final databases = memoryDatabases();
    final handlers = [
      ClientsSyncHandler(
          const ClientsLocalDataSource(), ClientsRemoteDataSourceImpl(dio)),
      ...CatalogSync.handlers(),
      ...EmployeesSync.handlers(),
      ...AppointmentsSync.handlers(),
      ...PaymentsSync.handlers(),
      DocumentSyncHandler(SharedDocs.businessSettings),
    ];
    final engine =
        SyncEngine(databases: databases, api: DioSyncApi(dio), handlers: handlers);
    await engine.syncNow();
    final db = await databases.require();
    final epochBefore =
        await (db.select(db.syncMeta)..where((m) => m.key.equals('server_epoch')))
            .getSingle();
    // Algo que solo existe en la base vieja de la app (debe irse) y algo
    // pendiente de subir (debe quedarse).
    await DocumentStore.put(db, CatalogDocs.services, 'fantasma',
        {'id': 'fantasma', 'name': 'Fantasma', 'isActive': true});
    final clients = ClientsRepositoryImpl(
        remote: ClientsRemoteDataSourceImpl(dio),
        store: OfflineStore(databases: databases));
    final suffix = DateTime.now().millisecondsSinceEpoch % 10000000;
    final pending = (await clients.createClient(ClientEntity(
            name: 'Pendiente',
            phone: '313${suffix.toString().padLeft(7, '0')}')))
        .getOrElse(() => throw StateError('alta'));

    final result = await Process.run('npm', ['run', 'sync:new-epoch'],
        workingDirectory: backendDir,
        environment: {'DB_NAME': dbName});
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');

    // El servidor aún no acepta la subida: solo la bajada (la bandeja sigue).
    final holdPush = SyncEngine(
        databases: databases, api: _HoldPush(DioSyncApi(dio)), handlers: handlers);
    await holdPush.syncNow();
    final epochAfter =
        await (db.select(db.syncMeta)..where((m) => m.key.equals('server_epoch')))
            .getSingle();
    expect(epochAfter.value, isNot(epochBefore.value));
    expect(await DocumentStore.get(db, 'services', 'fantasma'), isNull,
        reason: 'lo de la base vieja se fue');
    expect((await OutboxStore.all(db)).single.entityId, pending.id);
    expect((await clients.getClientById(pending.id!)).isRight(), true,
        reason: 'lo pendiente se reaplicó encima');
    expect((await clients.getClients(const ClientsQuery())).getOrElse(
            () => throw StateError('lista')).total,
        greaterThan(1));
    await holdPush.dispose();

    // Con la subida normal, la bandeja se vacía.
    await engine.syncNow();
    expect(await OutboxStore.all(db), isEmpty);
    await engine.dispose();
    await databases.close();
  },
      skip: url == null ||
              Platform.environment['SYNC_E2E_BACKEND_DIR'] == null ||
              Platform.environment['SYNC_E2E_DB'] == null
          ? 'Solo con SYNC_E2E_URL, SYNC_E2E_BACKEND_DIR y SYNC_E2E_DB (copia)'
          : null);
}

/// La bajada va al servidor real; la subida responde `retry` (aún no se
/// acepta), para ver la bajada completa con la bandeja intacta.
class _HoldPush implements SyncApi {
  final SyncApi inner;
  _HoldPush(this.inner);

  @override
  Future<List<MutationResult>> push(
          String deviceId, List<PushMutation> mutations) async =>
      [
        for (final m in mutations)
          MutationResult(mutationId: m.mutationId, status: MutationStatus.retry),
      ];

  @override
  Future<ChangesPage> changes(String cursor, {int limit = 500}) =>
      inner.changes(cursor, limit: limit);
}
