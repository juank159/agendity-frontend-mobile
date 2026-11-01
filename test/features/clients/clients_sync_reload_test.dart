import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/features/clients/domain/entities/paginated_list.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';
import 'package:login_signup/features/clients/domain/usecases/get_clients_page_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/import_clients_usecase.dart';
import 'package:login_signup/features/clients/presentation/controllers/clients_controller.dart';
import 'package:login_signup/features/notifications/domain/entities/app_notification.dart';
import 'package:login_signup/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:login_signup/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:login_signup/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';

import '../../core/sync/fake_sync_api.dart';

/// Repositorio paginado de verdad: [all] filtrado por búsqueda y cortado por
/// página, como la base local.
class _PagedClientsRepository implements ClientsRepository {
  List<ClientEntity> all;
  final queries = <ClientsQuery>[];
  Failure? failure;

  _PagedClientsRepository(this.all);

  @override
  Future<Either<Failure, PaginatedList<ClientEntity>>> getClients(
      ClientsQuery query) async {
    queries.add(query);
    final error = failure;
    if (error != null) return Left(error);
    final search = query.normalizedSearch?.toLowerCase();
    final matching = [
      for (final client in all)
        if (search == null || client.name.toLowerCase().contains(search))
          client,
    ];
    final start = (query.page - 1) * query.limit;
    final items = matching.skip(start).take(query.limit).toList();
    final totalPages = (matching.length + query.limit - 1) ~/ query.limit;
    return Right(PaginatedList(
      items: items,
      total: matching.length,
      page: query.page,
      limit: query.limit,
      totalPages: totalPages,
      hasNextPage: query.page < totalPages,
      hasPrevPage: query.page > 1,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotificationsRepository implements NotificationsRepository {
  Either<Failure, List<AppNotification>> result = const Right([]);
  int calls = 0;

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications() async {
    calls++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<ClientEntity> _clients(int count, {String prefix = 'Cliente'}) => [
      for (var i = 1; i <= count; i++)
        ClientEntity(
            id: '$prefix-$i',
            name: '$prefix ${i.toString().padLeft(3, '0')}',
            lastname: 'Ruiz',
            phone: '300${i.toString().padLeft(7, '0')}'),
    ];

/// Recarga por sincronización (7.05d): la lista no vuelve a la página 1 ni
/// pierde búsqueda y filtros, y no enseña el indicador de carga.
void main() {
  late LocalDatabaseHolder databases;
  late SyncEngine engine;
  late SyncController sync;

  setUp(() {
    Get.testMode = true;
    databases = memoryDatabases();
    engine = SyncEngine(databases: databases, api: FakeSyncServer());
    sync = Get.put<SyncController>(SyncController(engine), permanent: true);
  });

  tearDown(() async {
    Get.reset();
    await engine.dispose();
    await databases.close();
  });

  /// Lo que hace el `SyncController` al terminar una pasada correcta.
  Future<void> finishSync() async {
    sync.dataVersion.value++;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('ClientsController', () {
    late _PagedClientsRepository repo;

    ClientsController putController() => Get.put(ClientsController(
          getClientsPageUseCase: GetClientsPageUseCase(repo),
          importClientsUseCase: ImportClientsUseCase(repo),
          readDeviceContacts: () async => const [],
        ));

    Future<ClientsController> loaded() async {
      final controller = putController();
      await controller.loadClients();
      return controller;
    }

    test('con 2 páginas cargadas, la recarga por sync deja las 2', () async {
      repo = _PagedClientsRepository(_clients(45));
      final controller = await loaded();
      await controller.loadMoreClients();
      expect(controller.clients, hasLength(40));

      // Llega un cliente nuevo por la sincronización.
      repo.all = [..._clients(45), ..._clients(1, prefix: 'Nuevo')];
      repo.queries.clear();
      final loadingStates = <bool>[];
      final worker = ever<bool>(controller.isLoading, loadingStates.add);
      addTearDown(worker.dispose);

      await finishSync();

      expect(controller.clients, hasLength(40));
      expect(controller.clients.first.id, 'Cliente-1');
      expect(controller.clients.last.id, 'Cliente-40');
      expect(controller.totalRecords.value, 46);
      expect(controller.hasNextPage.value, isTrue);
      expect([for (final q in repo.queries) q.page], [1, 2]);
      expect(loadingStates, isEmpty, reason: 'sin indicador de carga');

      // El scroll infinito sigue desde la página 3.
      repo.queries.clear();
      await controller.loadMoreClients();
      expect(repo.queries.single.page, 3);
      expect(controller.clients, hasLength(46));
      expect(controller.hasNextPage.value, isFalse);
    });

    test('una búsqueda y un filtro activos se mantienen', () async {
      repo = _PagedClientsRepository(
          [..._clients(30, prefix: 'Ana'), ..._clients(30, prefix: 'Luis')]);
      final controller = putController();
      controller.searchController.text = 'ana';
      controller.searchQuery.value = 'ana';
      controller.applyWithoutConsent(true);
      // Deja pasar el `debounce` de la búsqueda (500 ms), que recarga.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await controller.loadMoreClients();
      expect(controller.clients, hasLength(30));

      repo.queries.clear();
      await finishSync();

      expect(controller.clients, hasLength(30));
      expect(controller.clients.every((c) => c.name.startsWith('Ana')),
          isTrue);
      expect(repo.queries, hasLength(2));
      for (final query in repo.queries) {
        expect(query.normalizedSearch, 'ana');
        expect(query.withoutConsent, isTrue);
      }
      expect(controller.searchQuery.value, 'ana');
      expect(controller.searchController.text, 'ana');
      expect(controller.withoutConsent.value, isTrue);
    });

    test('si la recarga falla, se conserva lo cargado sin error', () async {
      repo = _PagedClientsRepository(_clients(45));
      final controller = await loaded();
      await controller.loadMoreClients();

      repo.failure = const ServerFailure(message: 'Base local no disponible');
      await finishSync();

      expect(controller.clients, hasLength(40));
      expect(controller.error.value, isNull);
    });

    test('la lista se actualiza aunque haya menos clientes', () async {
      repo = _PagedClientsRepository(_clients(45));
      final controller = await loaded();
      await controller.loadMoreClients();

      repo.all = _clients(15);
      await finishSync();

      expect(controller.clients, hasLength(15));
      expect(controller.hasNextPage.value, isFalse);
      expect(controller.totalRecords.value, 15);
    });
  });

  group('NotificationsController', () {
    late _FakeNotificationsRepository repo;

    const aviso = AppNotification(
        id: 'n1', type: 'reminder', title: 'Recordatorio', message: 'Cita');

    test('la recarga por sync no enseña el indicador de carga', () async {
      repo = _FakeNotificationsRepository()..result = const Right([aviso]);
      final controller = Get.put(NotificationsController(
          getNotificationsUseCase: GetNotificationsUseCase(repo)));
      await Future<void>.delayed(Duration.zero);
      expect(controller.notifications, hasLength(1));

      final loadingStates = <bool>[];
      final worker = ever<bool>(controller.isLoading, loadingStates.add);
      addTearDown(worker.dispose);
      repo.result = const Left(ServerFailure(message: 'Base local no disponible'));
      await finishSync();

      expect(repo.calls, 2);
      expect(loadingStates, isEmpty);
      expect(controller.notifications, hasLength(1));
      expect(controller.error.value, isNull);
    });
  });
}
