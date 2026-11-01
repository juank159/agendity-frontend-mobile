import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/sync/document_sync_handler.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/core/sync/sync_models.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:login_signup/features/appointments/data/sync/appointments_sync.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_to_reschedule_usecase.dart';
import 'package:login_signup/features/appointments/presentation/controllers/sync_attention_controller.dart';
import 'package:login_signup/features/clients/data/datasources/clients_local_datasource.dart';
import 'package:login_signup/features/clients/data/sync/clients_sync_handler.dart';
import 'package:login_signup/features/employees/data/sync/employees_sync.dart';
import 'package:login_signup/features/services/data/sync/catalog_sync.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';

import '../session/memory_token_store.dart';
import 'fake_sync_api.dart';

/// 7.05c: una cita hecha en este teléfono choca con otra que reservó otro
/// dispositivo. El servidor la guarda "para mover" (`conflict` con
/// `saved: true`) y la marca llega con la bajada de esa misma pasada: al
/// terminarla, sin esperar otro intervalo, la cita local queda por mover y
/// el aviso de la agenda (`SyncAttentionController`) la cuenta.
void main() {
  late LocalDatabaseHolder databases;
  late AppDatabase db;
  late FakeSyncServer server;
  late SyncEngine engine;
  late OfflineStore store;
  late AppointmentsRepositoryImpl appointments;
  late SyncController sync;
  late SyncAttentionController attention;

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() async {
    Get.testMode = true;
    BusinessTimeZone.clock = () => DateTime.utc(2026, 11, 1, 13);
    databases = memoryDatabases();
    server = FakeSyncServer();
    engine = SyncEngine(databases: databases, api: server, handlers: [
      ClientsSyncHandler(const ClientsLocalDataSource()),
      ...CatalogSync.handlers(),
      ...EmployeesSync.handlers(),
      ...AppointmentsSync.handlers(),
      DocumentSyncHandler(SharedDocs.businessSettings),
    ]);
    store = OfflineStore(databases: databases);
    db = await databases.require();
    server
      ..serverUpsertClient('cli-1', {'name': 'Camila', 'phone': '3001112222'})
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
        'roles': [
          {'name': 'Employee'}
        ],
      })
      ..serverUpsert('user_services', 'us-1', {
        'userId': 'pro-1',
        'serviceId': 'svc-1',
        'isActive': true,
      })
      ..serverUpsert('business_settings', 'owner-1', {
        'tenant_id': 'owner-1',
        'name': 'Estudio A',
        'timezone': 'America/Bogota',
      });
    await engine.syncNow();

    final tokens = MemoryTokenStore();
    final session = SessionController(SessionService(
        tokenStore: tokens, repository: SessionRepository(tokens)));
    session.session.value =
        Session(token: 't', userId: 'owner-1', name: 'Ana', roles: ['Owner']);
    appointments = AppointmentsRepositoryImpl(
        AppointmentsRemoteDataSourceImpl(Dio()),
        store: store);
    sync = SyncController(engine, announce: (_) {})..onInit();
    Get.put(sync);
    attention = SyncAttentionController(
      getAppointmentsToRescheduleUseCase:
          GetAppointmentsToRescheduleUseCase(appointments),
      session: session,
    )..onInit();
    await settle();
  });

  tearDown(() async {
    attention.onClose();
    sync.onClose();
    Get.reset();
    BusinessTimeZone.clock = DateTime.now;
    await engine.dispose();
    await databases.close();
  });

  test('conflicto guardado: la cita queda por mover al terminar la pasada',
      () async {
    expect(attention.toRescheduleCount.value, 0);
    final created = (await appointments.createAppointment(NewAppointment(
            clientId: 'cli-1',
            professionalId: 'pro-1',
            serviceIds: const ['svc-1'],
            start: DateTime(2026, 11, 2, 14))))
        .getOrElse(() => throw StateError('cita'));
    expect(created.needsReschedule, isFalse);

    // Otro dispositivo ya ocupó la hora: el servidor la guarda para mover
    // (forma de `appointmentOutcome` en `sync-push.service.ts`) y la deja
    // en el feed con la marca.
    server.forced['appointment.create'] = (mutationId) {
      server.serverUpsert('appointments', created.id, {
        'professionalId': 'pro-1',
        'client': {'id': 'cli-1', 'name': 'Camila', 'lastname': ''},
        'professional': {'id': 'pro-1', 'name': 'Laura', 'lastname': 'Gómez'},
        'services': [
          {
            'id': 'svc-1',
            'name': 'Cejas en hilo',
            'duration': 45,
            'price': '45000.00',
            'appointment_price': '45000.00',
          },
        ],
        'date': '2026-11-02T14:00:00.000-05:00',
        'timezone': 'America/Bogota',
        'status': 'PENDING',
        'payment_status': 'PENDING',
        'total_price': '45000.00',
        'needsReschedule': true,
        'syncConflict': 'SLOT_UNAVAILABLE',
      });
      return MutationResult(
        mutationId: mutationId,
        status: MutationStatus.conflict,
        code: 'SLOT_UNAVAILABLE',
        message: 'Horario no disponible',
        saved: true,
      );
    };

    await engine.syncNow();
    await settle();

    // Salió de la bandeja (el servidor la guardó) y la bajada trajo la marca.
    expect(await OutboxStore.all(db), isEmpty);
    final local = (await appointments.getAppointment(created.id))
        .getOrElse(() => throw StateError('leer'));
    expect(local.needsReschedule, isTrue);
    expect(local.syncConflict, 'SLOT_UNAVAILABLE');

    // Sin recargar a mano: el fin de la pasada avisa a las pantallas.
    expect(attention.toRescheduleCount.value, 1);
  });

  test('cada pasada correcta avisa una vez; una sin red no', () async {
    final before = sync.dataVersion.value;
    await engine.syncNow();
    await settle();
    expect(sync.dataVersion.value, before + 1);

    server.offline = true;
    await engine.syncNow();
    await settle();
    expect(sync.dataVersion.value, before + 1);
  });
}
