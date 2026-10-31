import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/sync/document_sync_handler.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/core/sync/sync_models.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:login_signup/features/appointments/data/sync/appointments_sync.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';
import 'package:login_signup/features/clients/data/datasources/clients_local_datasource.dart';
import 'package:login_signup/features/clients/data/sync/clients_sync_handler.dart';
import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/data/repositories/employees_repository_impl.dart';
import 'package:login_signup/features/employees/data/sync/employees_sync.dart';
import 'package:login_signup/features/notifications/data/models/app_notification_model.dart';
import 'package:login_signup/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:login_signup/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:login_signup/features/payments/data/sync/payments_sync.dart';
import 'package:login_signup/features/services/data/repositories/categories_repository_impl.dart';
import 'package:login_signup/features/services/data/repositories/services_repository_impl.dart';
import 'package:login_signup/features/services/data/sync/catalog_sync.dart';
import 'package:login_signup/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:login_signup/features/settings/data/repositories/settings_repository_impl.dart';

import '../session/memory_token_store.dart';
import 'fake_sync_api.dart';

/// Cada handler de la 10.02b con el motor y un servidor simulado: la bajada
/// llena la base local y los repositorios la leen sin red.
void main() {
  late LocalDatabaseHolder databases;
  late AppDatabase db;
  late FakeSyncServer server;
  late SyncEngine engine;
  late OfflineStore store;

  setUp(() async {
    databases = memoryDatabases();
    server = FakeSyncServer();
    engine = SyncEngine(databases: databases, api: server, handlers: [
      ClientsSyncHandler(const ClientsLocalDataSource()),
      ...CatalogSync.handlers(),
      ...EmployeesSync.handlers(),
      ...AppointmentsSync.handlers(),
      ...PaymentsSync.handlers(),
      DocumentSyncHandler(SharedDocs.businessSettings),
      DocumentSyncHandler(AppNotificationModel.kind),
    ]);
    store = OfflineStore(databases: databases);
    db = await databases.require();
    // Lo que el negocio tiene en el servidor (forma del feed).
    server
      ..serverUpsertClient('cli-1', {'name': 'Ana', 'phone': '3001112222'})
      ..serverUpsert('categories', 'cat-1', {'name': 'Cejas', 'isActive': true})
      ..serverUpsert('services', 'svc-1', {
        'name': 'Cejas en hilo',
        'price': '45000.00',
        'duration': 45,
        'categoryId': 'cat-1',
        'category': 'cat-1',
        'isActive': true,
      })
      ..serverUpsert('users', 'pro-1', {
        'name': 'Laura',
        'lastname': 'Gómez',
        'isActive': true,
        'is_email_verified': true,
        'commission_percentage': '30.00',
        'roles': [
          {'name': 'Employee'}
        ],
      })
      ..serverUpsert('user_services', 'us-1', {
        'userId': 'pro-1',
        'serviceId': 'svc-1',
        'commissionPercentage': null,
        'isActive': true,
      })
      ..serverUpsert('schedules', 'sch-1', {
        'user': 'pro-1',
        'day_of_week': 2,
        'start_time': '09:00:00',
        'end_time': '18:00:00',
        'is_available': true,
      })
      ..serverUpsert('appointments', 'apt-1', {
        'professionalId': 'pro-1',
        'client': {'id': 'cli-1', 'name': 'Ana', 'lastname': ''},
        'professional': {'id': 'pro-1', 'name': 'Laura', 'lastname': 'Gómez'},
        'services': [
          {'id': 'svc-1', 'name': 'Cejas en hilo', 'duration': 45,
            'price': '45000.00', 'appointment_price': '45000.00'},
        ],
        'date': '2026-11-03T10:00:00.000-05:00',
        'timezone': 'America/Bogota',
        'status': 'PENDING',
        'payment_status': 'PENDING',
        'total_price': '45000.00',
      })
      ..serverUpsert('time_block', 'tb-1', {
        'user': 'pro-1',
        'start_datetime': '2026-11-03T13:00:00.000-05:00',
        'end_datetime': '2026-11-03T14:00:00.000-05:00',
        'timezone': 'America/Bogota',
      })
      ..serverUpsert('payments', 'pay-1', {
        'appointment': 'apt-1',
        'amount': '20000.00',
        'payment_method': 'CASH',
        'status': 'COMPLETED',
        'timezone': 'America/Bogota',
        'reviewRequired': null,
        'created_at': '2026-11-01T10:00:00.000-05:00',
      })
      ..serverUpsert('custom_payment_methods', 'cm-1',
          {'name': 'Nequi', 'isActive': true})
      ..serverUpsert('business_settings', 'owner-1', {
        'tenant_id': 'owner-1',
        'name': 'Estudio Ana',
        'slug': 'estudio-ana',
        'timezone': 'America/Caracas',
        'opening_hours': null,
      })
      ..serverUpsert('notifications', 'n-1', {
        'type': 'APPOINTMENT_REMINDER',
        'title': 'Cita en 1 hora',
        'message': 'Ana a las 10:00',
        'read': false,
        'created_at': '2026-11-03T09:00:00.000-05:00',
      })
      // Una entidad que la app no guarda (reseñas): se ignora sin fallar.
      ..serverUpsert('reviews', 'r-1', {'rating': 5});
    await engine.syncNow();
  });

  tearDown(() async {
    BusinessTimeZone.reset();
    await engine.dispose();
    await databases.close();
  });

  test('catálogo: servicios con categoría y categorías con conteo', () async {
    final services = (await ServicesRepositoryImpl(store).getServices())
        .getOrElse(() => []);
    expect(services.single.category!.name, 'Cejas');
    final categories = (await CategoriesRepositoryImpl(store).getCategories())
        .getOrElse(() => []);
    expect(categories.single.serviceCount, 1);
  });

  test('profesionales: servicios, comisión y horario', () async {
    final employees = (await EmployeesRepositoryImpl(
                EmployeesRemoteDataSourceImpl(Dio()),
                store: store,
                refresh: () async {})
            .getEmployees())
        .getOrElse(() => []);
    final laura = employees.single;
    expect(laura.offersService('svc-1'), true);
    expect(laura.commissionFor('svc-1'), 30);
    expect(laura.schedule['tuesday']!.start, '09:00');
  });

  test('citas, bloqueos, pagos y métodos de pago', () async {
    final appointments = AppointmentsRepositoryImpl(
        AppointmentsRemoteDataSourceImpl(Dio()),
        store: store);
    final list = (await appointments
            .getAppointments(AppointmentsRange.day(DateTime(2026, 11, 3))))
        .getOrElse(() => []);
    expect(list.single.client.name, 'Ana');
    expect(await DocumentStore.get(db, 'time_block', 'tb-1'), isNotNull);

    final payments = PaymentRepositoryImpl(store);
    final paid = (await payments.getAppointmentPayments('apt-1'))
        .getOrElse(() => []);
    expect(paid.single.amount, 20000);
    expect(
        (await payments.getActiveCustomPaymentMethods())
            .getOrElse(() => [])
            .single
            .name,
        'Nequi');
  });

  test('configuración (zona de la sesión) y avisos', () async {
    final tokens = MemoryTokenStore('jwt');
    final settings = SettingsRepositoryImpl(
      remote: SettingsRemoteDataSourceImpl(Dio()),
      session:
          SessionService(tokenStore: tokens, repository: SessionRepository(tokens)),
      store: store,
    );
    final read = (await settings.getSettings())
        .getOrElse(() => throw StateError('settings'));
    expect(read.name, 'Estudio Ana');
    expect(read.slug, 'estudio-ana');
    expect(BusinessTimeZone.current, 'America/Caracas');

    final notifications =
        (await NotificationsRepositoryImpl(store).getNotifications())
            .getOrElse(() => []);
    expect(notifications.single.title, 'Cita en 1 hora');
  });

  test('borrado y leave_scope de la bajada', () async {
    server
      ..serverDelete('services', 'svc-1')
      ..serverLeaveScope('appointments', 'apt-1');
    await engine.syncNow();
    expect(await DocumentStore.get(db, 'services', 'svc-1'), isNull);
    expect(await DocumentStore.get(db, 'appointments', 'apt-1'), isNull);
  });

  test('cliente fusionado: las citas pendientes pasan al cliente del servidor',
      () async {
    BusinessTimeZone.clock = () => DateTime.utc(2026, 11, 1, 13);
    addTearDown(() => BusinessTimeZone.clock = DateTime.now);
    // Sin conexión: un cliente nuevo con un teléfono que ya existe y una cita.
    server.offline = true;
    await store.write((db, sink) async {
      final entry = await sink.add(
          type: 'client.create',
          entity: 'clients',
          entityId: 'cli-local',
          payload: {'name': 'Ana B', 'lastname': '', 'phone': '3001112222'});
      await ClientsSyncHandler(const ClientsLocalDataSource())
          .replay(db, entry);
    });
    final appointments = AppointmentsRepositoryImpl(
        AppointmentsRemoteDataSourceImpl(Dio()),
        store: store);
    final created = (await appointments.createAppointment(NewAppointment(
            clientId: 'cli-local',
            professionalId: 'pro-1',
            serviceIds: const ['svc-1'],
            start: DateTime(2026, 11, 4, 10))))
        .getOrElse(() => throw StateError('cita'));
    expect(created.client.id, 'cli-local');

    server.offline = false;
    server.forced['appointment.create'] = (mid) =>
        MutationResult(mutationId: mid, status: MutationStatus.applied);
    await engine.syncNow();
    final remapped = (await appointments.getAppointment(created.id))
        .getOrElse(() => throw StateError('leer'));
    expect(remapped.client.id, 'cli-1');
    expect(await OutboxStore.all(db), isEmpty);
  });
}
