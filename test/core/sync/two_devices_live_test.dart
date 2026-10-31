// 10.04 (D-18): dos dispositivos de verdad, uno sin conexión, y la web de
// reservas, contra el servidor real sobre una COPIA de `agendity_demo`.
//
// Cada "dispositivo" es la app real sin UI: su propio archivo SQLite (drift),
// sus repositorios, su `OfflineStore`, su `SyncEngine` y su Dio con su token.
// La red se simula por dispositivo (sin conexión y corte a mitad de lote).
// Se eligió un test de Dart y no `integration_test`: así corren dos
// instancias independientes en el mismo proceso con la red bajo control, y lo
// que se prueba son los datos (nada se pierde), no la pantalla.
//
//   TZ=Asia/Tokyo SYNC_E2E_URL=http://127.0.0.1:3410/api \
//   SYNC_E2E_DB=<copia> flutter test test/core/sync/two_devices_live_test.dart
//
// ESCRIBE en el servidor: solo contra una copia de la demo (7.01).
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/network/interceptors/auth_interceptor.dart';
import 'package:login_signup/core/sync/document_sync_handler.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_api.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/core/sync/sync_entity_handler.dart';
import 'package:login_signup/core/sync/sync_models.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:login_signup/features/appointments/data/sync/appointments_sync.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/clients/data/datasources/clients_local_datasource.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/clients/data/repositories/client_repository_impl.dart';
import 'package:login_signup/features/clients/data/sync/clients_sync_handler.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/features/employees/data/sync/employees_sync.dart';
import 'package:login_signup/features/notifications/data/models/app_notification_model.dart';
import 'package:login_signup/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:login_signup/features/payments/data/sync/payments_sync.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/services/data/sync/catalog_sync.dart';

import '../session/memory_token_store.dart';
import 'fake_sync_api.dart' show offlineError;

const _password = 'Clave@2026a';
const _zone = 'America/Bogota';

/// Red simulada de un dispositivo: sin conexión, o corte después de que el
/// servidor aplicó las N primeras mutaciones del lote (sin respuesta).
class SimulatedNetwork implements SyncApi {
  final SyncApi inner;
  bool offline = false;
  int? cutAfter;

  /// Último resultado del servidor por `mutation_id`.
  final results = <String, MutationResult>{};

  /// Lotes enviados (ids), para ver los reenvíos.
  final batches = <List<String>>[];

  SimulatedNetwork(this.inner);

  @override
  Future<List<MutationResult>> push(
      String deviceId, List<PushMutation> mutations) async {
    if (offline) throw offlineError();
    batches.add([for (final m in mutations) m.mutationId]);
    final cut = cutAfter;
    if (cut != null) {
      cutAfter = null;
      await inner.push(deviceId, mutations.take(cut).toList());
      throw offlineError(); // el servidor aplicó, la app no se enteró
    }
    final answer = await inner.push(deviceId, mutations);
    for (final r in answer) {
      results[r.mutationId] = r;
    }
    return answer;
  }

  @override
  Future<ChangesPage> changes(String cursor, {int limit = 500}) async {
    if (offline) throw offlineError();
    return inner.changes(cursor, limit: limit);
  }
}

/// Una instancia de la app (sin UI) con su base en archivo.
class Device {
  final String name;
  final Dio dio;
  final SimulatedNetwork net;
  final LocalDatabaseHolder databases;
  final OfflineStore store;
  final SyncEngine engine;
  final List<SyncEntityHandler> handlers;
  final String userId;

  Device._(this.name, this.dio, this.net, this.databases, this.store,
      this.engine, this.handlers, this.userId);

  static Future<Device> login(
      String name, String url, String email, Directory dir) async {
    final tokens = MemoryTokenStore();
    final dio = buildApiClient(
        baseUrl: url,
        tokenStore: tokens,
        enableLogs: false,
        retryDelay: (_) => Duration.zero);
    final login = await dio.post<Map<String, dynamic>>('/auth/login',
        data: {'email': email, 'password': _password},
        options: Options(extra: {AuthInterceptor.publicKey: true}));
    tokens.token = login.data!['token'] as String;
    final userId = (login.data!['user'] as Map)['id'] as String;
    final net = SimulatedNetwork(DioSyncApi(dio));
    // Sin conexión, tampoco sale ninguna otra llamada del dispositivo.
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (net.offline) {
        handler.reject(DioException(
            requestOptions: options, type: DioExceptionType.connectionError));
      } else {
        handler.next(options);
      }
    }));
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final file = File('${dir.path}/$name.sqlite');
    final databases = LocalDatabaseHolder(
      currentUserId: () async => userId,
      open: (_) => NativeDatabase(file),
    );
    final handlers = <SyncEntityHandler>[
      ClientsSyncHandler(
          const ClientsLocalDataSource(), ClientsRemoteDataSourceImpl(dio)),
      ...CatalogSync.handlers(),
      ...EmployeesSync.handlers(),
      ...AppointmentsSync.handlers(),
      ...PaymentsSync.handlers(),
      DocumentSyncHandler(SharedDocs.businessSettings),
      DocumentSyncHandler(AppNotificationModel.kind),
    ];
    final engine =
        SyncEngine(databases: databases, api: net, handlers: handlers);
    return Device._(name, dio, net, databases,
        OfflineStore(databases: databases), engine, handlers, userId);
  }

  ClientsRepositoryImpl get clients => ClientsRepositoryImpl(
      remote: ClientsRemoteDataSourceImpl(dio), store: store);
  AppointmentsRepositoryImpl get appointments =>
      AppointmentsRepositoryImpl(AppointmentsRemoteDataSourceImpl(dio),
          store: store);
  PaymentRepositoryImpl get payments => PaymentRepositoryImpl(store);

  Future<AppDatabase> db() => databases.require();

  /// Sincroniza hasta que la bandeja no tenga nada pendiente que enviar.
  Future<void> sync() async {
    for (var i = 0; i < 5; i++) {
      await engine.syncNow();
      final db = await this.db();
      final pending = (await OutboxStore.all(db))
          .where((e) => e.status == OutboxStatus.pending);
      if (pending.isEmpty) return;
    }
  }

  /// Ids locales por entidad (lo que la app muestra), sin copias de sombra.
  Future<Map<String, Set<String>>> localIds() async {
    final db = await this.db();
    final out = <String, Set<String>>{};
    for (final row in await db.select(db.localDocuments).get()) {
      if (row.entity.startsWith('@')) continue;
      out.putIfAbsent(row.entity, () => {}).add(row.id);
    }
    out['clients'] = {
      for (final row in await db.select(db.localClients).get()) row.id
    };
    return out;
  }

  Set<String> get entities => {for (final h in handlers) h.entity};

  Future<void> close() async {
    await engine.dispose();
    await databases.close();
  }
}

/// Lo que el servidor le da a [dio] (con sus permisos): bajada completa.
Future<Map<String, Map<String, Map<String, dynamic>>>> serverView(
    Dio dio) async {
  final api = DioSyncApi(dio);
  final out = <String, Map<String, Map<String, dynamic>>>{};
  var cursor = '0';
  while (true) {
    final page = await api.changes(cursor);
    for (final c in page.changes) {
      final bucket = out.putIfAbsent(c.entity, () => {});
      if (c.op == ChangeOp.upsert && c.data != null) {
        bucket[c.id] = c.data!;
      } else {
        bucket.remove(c.id);
      }
    }
    cursor = page.cursor;
    if (!page.hasMore) return out;
  }
}

/// Consulta de solo lectura sobre la copia (comprobaciones cruzadas).
String sql(String db, String query) {
  final r = Process.runSync('docker',
      ['exec', 'ecommerce', 'psql', '-U', 'juank', '-d', db, '-Atc', query]);
  return (r.stdout as String).trim();
}

void main() {
  final url = Platform.environment['SYNC_E2E_URL'];
  final copy = Platform.environment['SYNC_E2E_DB'];

  test('10.04: dos dispositivos y la web, uno sin conexión; nada se pierde',
      () async {
    expect(copy, isNot(anyOf('agendity_demo', 'ecommerce')),
        reason: 'solo contra una copia');
    final dir = await Directory.systemTemp.createTemp('t1004_');
    addTearDown(() => dir.delete(recursive: true));
    BusinessTimeZone.use(_zone);
    addTearDown(BusinessTimeZone.reset);
    final findings = <String>[];
    void note(bool ok, String what, [Object? info]) {
      // ignore: avoid_print
      print(
          '${ok ? 'PASS' : 'FAIL'}  $what${info == null ? '' : '  -> $info'}');
      if (!ok) findings.add('$what: $info');
    }

    final a =
        await Device.login('A_duena', url!, 'marcela.rojas@example.com', dir);
    final b = await Device.login('B_ana', url, 'ana.gomez@example.com', dir);
    addTearDown(a.close);
    addTearDown(b.close);
    await a.sync();
    await b.sync();
    note(
        a.engine.current.lastError == null &&
            b.engine.current.lastError == null,
        'carga inicial de A y B sin errores');
    note(
        DateTime.now().timeZoneName != 'COT' &&
            DateTime.now().timeZoneOffset != const Duration(hours: -5),
        'el proceso NO está en la zona de Bogotá',
        DateTime.now().timeZoneName);

    final adb = await a.db();
    final settings =
        (await DocumentStore.list(adb, SharedDocs.businessSettings.entity))
            .single;
    note(settings['timezone'] == _zone, 'zona del negocio bajada',
        settings['timezone']);
    final slug = settings['slug'] as String;
    final users = await DocumentStore.list(adb, 'users');
    String userId(String email) =>
        users.firstWhere((u) => u['email'] == email)['id'] as String;
    final laura = userId('laura.perez@example.com');
    final ana = userId('ana.gomez@example.com');
    final services = await DocumentStore.list(adb, 'services');
    String serviceId(String name) =>
        services.firstWhere((s) => s['name'] == name)['id'] as String;
    final cejas = serviceId('Cejas semipermanente');
    final bozo = serviceId('Depilación de bozo');
    final axilas = serviceId('Depilación de axilas');

    final existingClients =
        (await a.clients.getClients(const ClientsQuery(limit: 200)))
            .getOrElse(() => throw StateError('clientes'))
            .items;
    final daniela = existingClients.firstWhere((c) => c.name == 'Daniela');
    final aAppointments = (await a.appointments
            .getAppointments(AppointmentsRange.day(DateTime(2026, 10, 31))))
        .getOrElse(() => throw StateError('citas'));
    final pastPending = aAppointments.firstWhere((x) =>
        x.professionalId == laura &&
        x.client.name.startsWith('Sofía') &&
        x.status.name == 'PENDING');
    final isabella =
        aAppointments.firstWhere((x) => x.client.name.startsWith('Isabella'));

    // ───────────── 1. A sin conexión ─────────────
    a.net.offline = true;
    final suffix = DateTime.now().millisecondsSinceEpoch % 1000000;
    final phone = '315${suffix.toString().padLeft(7, '0')}';
    final newClient = (await a.clients.createClient(
            ClientEntity(name: 'Paula', lastname: 'Sinred', phone: phone)))
        .getOrElse(() => throw StateError('cliente sin red'));
    // Un día distinto por corrida (la reserva web de una corrida anterior
    // ocuparía las 15:00), nunca domingo (Laura no trabaja).
    final previousRuns = int.parse(
        sql(copy!, "select count(*) from appointments where source = 'WEB'"));
    var day = DateTime(2026, 11, 3 + previousRuns);
    if (day.weekday == DateTime.sunday) day = day.add(const Duration(days: 1));
    final dayText = '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final offlineAppt = (await a.appointments.createAppointment(NewAppointment(
            clientId: newClient.id!,
            professionalId: laura,
            serviceIds: [cejas, bozo, axilas],
            start: DateTime(day.year, day.month, day.day, 15))))
        .getOrElse(() => throw StateError('cita sin red'));
    note(
        offlineAppt.startTime.hour == 15 && offlineAppt.totalPrice == 160000,
        'cita sin red: 15:00 de pared y \$160.000',
        '${offlineAppt.startTime} ${offlineAppt.totalPrice}');
    final deposit = (await a.payments.createPayment(PaymentEntity(
            appointmentId: offlineAppt.id,
            amount: 50000,
            paymentMethod: PaymentMethod.CASH)))
        .getOrElse(() => throw StateError('anticipo sin red'));
    final newPhone = '3103330${(suffix % 1000).toString().padLeft(3, '0')}';
    (await a.clients.updateClient(daniela.copyWith(phone: newPhone)))
        .getOrElse(() => throw StateError('editar teléfono'));
    (await a.appointments.completeAppointment(pastPending.id))
        .getOrElse(() => throw StateError('completar pasada'));
    final queued = await OutboxStore.all(adb);
    note(queued.length == 5, 'A encoló 5 mutaciones sin red',
        [for (final e in queued) e.type]);
    await a.engine.syncNow();
    note(!a.engine.current.online, 'A se sabe sin conexión');
    note((await OutboxStore.all(adb)).length == 5,
        'sin red la bandeja no se toca');

    // ───────────── 2. La web y B, con conexión ─────────────
    final web = Dio(BaseOptions(baseUrl: url, validateStatus: (_) => true));
    final booking =
        await web.post<dynamic>('/public/businesses/$slug/bookings', data: {
      'service_ids': [cejas],
      'professional_id': laura,
      'start': '${dayText}T15:00:00-05:00',
      'client': {
        'name': 'Web',
        'lastname': 'Reserva',
        'phone': '31899${suffix.toString().padLeft(5, '0').substring(0, 5)}'
      },
    });
    note(booking.statusCode == 201, 'reserva web con Laura a las 15:00',
        '${booking.statusCode} ${booking.data}');
    // La respuesta pública no trae el id: se busca en la copia.
    final bookingId = sql(
        copy,
        "select id from appointments where source='WEB' and professional_id='$laura' "
        "and date = '${dayText}T15:00:00-05:00' order by created_at desc limit 1");
    note(bookingId.isNotEmpty, 'la reserva web está en el servidor', bookingId);

    (await b.appointments.completeAppointment(isabella.id))
        .getOrElse(() => throw StateError('Ana completa la suya'));
    await b.sync();
    note(
        (await OutboxStore.all(await b.db())).isEmpty,
        'B (Ana) subió su cambio',
        b.net.results.values.map((r) => r.status.name).toList());

    // ───────────── 3. Otra persona: mismo teléfono, con conexión ─────────────
    final lauraDio =
        (await Device.login('C_laura', url, 'laura.perez@example.com', dir))
            .dio;
    final dup = await lauraDio.post<Map<String, dynamic>>('/clients',
        data: {'name': 'Paula', 'lastname': 'Online', 'phone': phone});
    final onlineClientId = dup.data!['id'] as String;
    note(dup.statusCode == 201, 'Laura crea con conexión el mismo teléfono',
        onlineClientId);

    // ───────────── 4. A vuelve ─────────────
    a.net.offline = false;
    await a.sync();
    final left = await OutboxStore.all(adb);
    note(left.isEmpty, 'bandeja de A vacía tras sincronizar',
        [for (final e in left) '${e.type}:${e.status.name}:${e.code}']);
    // 5a. Toda mutación tiene resultado.
    final results = {
      for (final e in queued) e.type: a.net.results[e.mutationId]
    };
    note(
        results.values
            .every((r) => r != null && r.status != MutationStatus.retry),
        'toda mutación tiene resultado',
        {
          for (final e in results.entries)
            e.key:
                '${e.value?.status.name}/${e.value?.code}/${e.value?.mergedInto ?? ''}'
        });

    final serverA = await serverView(a.dio);
    // 5b. Ninguna fila se pierde (por id).
    note(serverA['appointments']!.containsKey(offlineAppt.id),
        'la cita de A existe en el servidor');
    note(serverA['payments']!.containsKey(deposit.id),
        'el anticipo de A existe en el servidor');
    note(serverA['appointments']!.containsKey(bookingId),
        'la reserva web existe', bookingId);
    // 5c. La cita de A queda por mover y no ocupa hueco.
    final syncedAppt = (await a.appointments.getAppointment(offlineAppt.id))
        .getOrElse(() => throw StateError('cita sincronizada'));
    note(
        syncedAppt.needsReschedule &&
            syncedAppt.syncConflict == 'SLOT_UNAVAILABLE',
        'cita de A por mover (SLOT_UNAVAILABLE)',
        '${syncedAppt.needsReschedule} ${syncedAppt.syncConflict}');
    final slots = await a.dio
        .get<List<dynamic>>('/appointments/available-slots', queryParameters: {
      'professional_id': laura,
      'date': dayText,
      'service_ids': cejas
    });
    final hours = [for (final s in slots.data!) s.toString().substring(11, 16)];
    note(
        hours.contains('15:30') && !hours.contains('15:00'),
        'la cita por mover no ocupa hueco (15:30 libre, 15:00 de la web ocupada)',
        hours);
    // 5d. Fusión por teléfono y citas reasignadas.
    final aliased = (await a.clients.getClientById(newClient.id!))
        .getOrElse(() => throw StateError('alias'));
    note(aliased.id == onlineClientId, 'cliente de A fusionado con el de Laura',
        aliased.id);
    note(
        syncedAppt.client.id == onlineClientId,
        'la cita de A apunta al cliente fusionado (local)',
        syncedAppt.client.id);
    final apptOnServer = serverA['appointments']![offlineAppt.id]!;
    final serverClientId =
        (apptOnServer['client'] as Map?)?['id'] ?? apptOnServer['clientId'];
    note(serverClientId == onlineClientId,
        'la cita de A apunta al cliente fusionado (servidor)', serverClientId);
    note(sql(copy, "select count(*) from clients where phone='$phone'") == '1',
        'un solo cliente con ese teléfono en el servidor');
    note(!(await a.localIds())['clients']!.contains(newClient.id),
        'el id local del duplicado ya no está en la base de A');
    // 5e. Anticipo aplicado o en revisión con razón.
    final depositOnServer = serverA['payments']![deposit.id]!;
    final depositResult = results['payment.create'];
    note(
        depositResult?.status == MutationStatus.applied ||
            (depositResult?.status == MutationStatus.conflict &&
                depositResult?.code != null),
        'anticipo aplicado o en revisión con razón',
        '${depositResult?.status.name} ${depositResult?.code} review=${depositOnServer['review_required'] ?? depositOnServer['reviewRequired']}');
    // Teléfono editado y cita pasada completada.
    note(
        sql(copy, "select phone from clients where id='${daniela.id}'") ==
            newPhone,
        'teléfono editado sin red llegó',
        newPhone);
    note(
        sql(copy,
                "select status from appointments where id='${pastPending.id}'") ==
            'COMPLETED',
        'cita pasada completada sin red llegó');
    // 7. Hora del negocio.
    note(
        sql(copy,
                "select to_char(date at time zone 'America/Bogota','YYYY-MM-DD HH24:MI') from appointments where id='${offlineAppt.id}'") ==
            '$dayText 15:00',
        'servidor: la cita de A a las 15:00 de Bogotá');
    note(
        apptOnServer['date']
            .toString()
            .startsWith('${dayText}T15:00:00.000-05:00'),
        'la bajada la da con -05:00',
        apptOnServer['date']);
    if (bookingId.isNotEmpty) {
      note(
          sql(copy,
                  "select to_char(date at time zone 'America/Bogota','HH24:MI')||' '||source||' '||status from appointments where id='$bookingId'") ==
              '15:00 WEB PENDING',
          'reserva web: 15:00 Bogotá, WEB, PENDING');
    }

    // 5f. A, B y el servidor coinciden (cada uno con sus permisos).
    await b.sync();
    Future<void> compare(Device d) async {
      final server = await serverView(d.dio);
      final local = await d.localIds();
      for (final entity in d.entities) {
        final s = server[entity]?.keys.toSet() ?? <String>{};
        final l = local[entity] ?? <String>{};
        note(
            s.length == l.length && s.containsAll(l),
            '${d.name}: $entity local = servidor (${l.length})',
            s.length == l.length && s.containsAll(l)
                ? null
                : 'faltan ${s.difference(l)} sobran ${l.difference(s)}');
      }
    }

    await compare(a);
    await compare(b);
    final bAppt = (await b.appointments.getAppointment(isabella.id))
        .getOrElse(() => throw StateError('Ana'));
    note(bAppt.status.name == 'COMPLETED', 'Ana ve su cita completada');
    final aIsabella = (await a.appointments.getAppointment(isabella.id))
        .getOrElse(() => throw StateError('A Isabella'));
    note(aIsabella.status.name == 'COMPLETED', 'A ve lo que hizo Ana');

    // 5g. B nunca recibe datos que no le tocan.
    final bdb = await b.db();
    note((await DocumentStore.list(bdb, 'payments')).isEmpty, 'B sin pagos');
    final bUserServices = await DocumentStore.list(bdb, 'user_services');
    note(bUserServices.every((u) => (u['userId'] ?? u['user_id']) == ana),
        'B solo con sus user_services (comisiones)', bUserServices.length);
    final bAppts = await DocumentStore.list(bdb, 'appointments');
    note(
        bAppts
            .every((x) => (x['professionalId'] ?? x['professional_id']) == ana),
        'B solo con sus citas',
        bAppts.length);
    final others =
        (await DocumentStore.list(bdb, 'users')).where((u) => u['id'] != ana);
    note(others.every((u) => u['email'] == null && u['phone'] == null),
        'B sin email ni teléfono de los demás', [
      for (final u in others) {'email': u['email'], 'phone': u['phone']}
    ]);
    final bRaw = jsonEncode(await serverView(b.dio));
    note(
        !bRaw.contains('commission') ||
            bUserServices.every((u) => (u['userId'] ?? u['user_id']) == ana),
        'la bajada de B no trae comisiones de otras');

    // ───────────── 6. Corte a mitad de un lote ─────────────
    a.net.offline = true;
    final extra = (await a.payments.createPayment(PaymentEntity(
            appointmentId: offlineAppt.id,
            amount: 20000,
            paymentMethod: PaymentMethod.TRANSFER)))
        .getOrElse(() => throw StateError('abono sin red'));
    (await a.payments.refundPayment(deposit.id!,
            amount: 5000, reason: 'Corte a mitad de lote'))
        .getOrElse(() => throw StateError('reembolso sin red'));
    final again = (await a.clients.getClientById(daniela.id!))
        .getOrElse(() => throw StateError('Daniela'));
    (await a.clients.updateClient(again.copyWith(notes: 'Nota tras el corte')))
        .getOrElse(() => throw StateError('nota'));
    final batch = await OutboxStore.all(adb);
    note(batch.length == 3, 'lote de 3 sin red',
        [for (final e in batch) e.type]);
    a.net.offline = false;
    a.net.cutAfter =
        2; // el servidor aplica el pago y el reembolso; sin respuesta
    await a.engine.syncNow();
    note((await OutboxStore.all(adb)).length == 3,
        'tras el corte, la bandeja sigue entera');
    await a.sync();
    note((await OutboxStore.all(adb)).isEmpty, 'reenvío: bandeja vacía');
    note(
        sql(copy,
                "select count(*) from payments where \"appointmentId\"='${offlineAppt.id}'") ==
            '2',
        'sin pagos duplicados (anticipo + abono)');
    note(
        sql(copy,
                "select refund_amount from payments where id='${deposit.id}'") ==
            '5000.00',
        'un solo reembolso de 5.000 (no doble)',
        sql(copy,
            "select refund_amount from payments where id='${deposit.id}'"));
    note(
        sql(copy, "select count(*) from payments where id='${extra.id}'") ==
            '1',
        'el abono existe una vez');
    final local = (await a.payments.getAppointmentPayments(offlineAppt.id))
        .getOrElse(() => []);
    note(
        local.length == 2 &&
            local.firstWhere((p) => p.id == deposit.id).refundAmount == 5000,
        'A ve 2 pagos y el reembolso una vez',
        [for (final p in local) '${p.amount}/${p.refundAmount}']);
    await compare(a);

    note(
        sql(copy,
                "select count(*) from sync_mutations where status = 'pending'") ==
            '0',
        'ninguna mutación quedó a medias en el servidor');
    final toMove = (await a.appointments.getAppointmentsToReschedule())
        .getOrElse(() => []);
    note(toMove.any((x) => x.id == offlineAppt.id),
        'A la ve en "citas por mover"');

    // ignore: avoid_print
    print('HALLAZGOS: ${findings.length}\n${findings.join('\n')}');
    expect(findings, isEmpty);
  },
      timeout: const Timeout(Duration(minutes: 5)),
      skip: url == null || copy == null
          ? 'Solo con SYNC_E2E_URL y SYNC_E2E_DB (copia)'
          : null);
}
