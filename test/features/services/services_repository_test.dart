import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/core/sync/sync_models.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/data/datasources/catalog_local_datasource.dart';
import 'package:login_signup/features/services/data/datasources/services_remote_datasource.dart';
import 'package:login_signup/features/services/data/models/my_service_model.dart';
import 'package:login_signup/features/services/domain/entities/my_service.dart';
import 'package:login_signup/features/services/domain/usecases/get_my_services_usecase.dart';
import 'package:login_signup/features/services/data/repositories/categories_repository_impl.dart';
import 'package:login_signup/features/services/data/repositories/services_repository_impl.dart';
import 'package:login_signup/features/services/data/sync/catalog_sync.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/failures/services_failures.dart';
import 'package:login_signup/features/services/domain/usecases/create_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/create_service_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/delete_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_all_services_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_offered_by_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_status_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_service_usecase.dart';

import '../../core/sync/fake_sync_api.dart';
import 'services_models_test.dart' show backendCategory, backendService;

Failure? leftOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => null);

T rightOf<T>(Either<Failure, T> result) =>
    result.getOrElse(() => throw StateError('Left: ${leftOf(result)}'));

const newService = ServiceEntity(
  name: '  Corte ',
  price: 20000,
  duration: 30,
  categoryId: 'cat-1',
);

/// Catálogo sin conexión (10.02b): lectura local, escrituras a local +
/// bandeja (`service.*`, `category.*`).
void main() {
  late LocalDatabaseHolder databases;
  late AppDatabase db;
  late ServicesRepositoryImpl services;
  late CategoriesRepositoryImpl categories;
  var ids = 0;

  setUp(() async {
    databases = memoryDatabases();
    ids = 0;
    final store = OfflineStore(
        databases: databases, newId: () => 'new-${++ids}');
    services = ServicesRepositoryImpl(store);
    categories = CategoriesRepositoryImpl(store);
    db = await databases.require();
    // Lo que bajó la sincronización: la categoría como id (`loadRelationIds`).
    await DocumentStore.put(db, CatalogDocs.categories, 'cat-1',
        backendCategory());
    await DocumentStore.put(db, CatalogDocs.categories, 'cat-2',
        backendCategory(id: 'cat-2', name: 'Pestañas'));
    for (final (id, name, active) in [
      ('srv-1', 'Cejas en hilo', true),
      ('srv-2', 'Tinte', false),
    ]) {
      await DocumentStore.put(db, CatalogDocs.services, id, {
        ...backendService(id: id, name: name, withCategory: false),
        'category': 'cat-1',
        'categoryId': 'cat-1',
        'isActive': active,
      });
    }
  });

  tearDown(() => databases.close());

  Future<List<OutboxEntry>> outbox() => OutboxStore.all(db);

  group('servicios', () {
    test('activos con su categoría; todos con los desactivados', () async {
      final active = rightOf(await GetServicesUseCase(services)(NoParams()));
      expect(active.map((s) => s.id), ['srv-1']);
      expect(active.single.category!.name, 'Cejas');
      final all = rightOf(await GetAllServicesUseCase(services)(NoParams()));
      expect(all.map((s) => s.id), ['srv-1', 'srv-2']);
    });

    test('alta: recortada, en local y service.create sin isActive', () async {
      final created =
          rightOf(await CreateServiceUseCase(services)(newService));
      expect(created.id, 'new-1');
      expect(created.name, 'Corte');
      expect(created.isActive, true);
      final entry = (await outbox()).single;
      expect(entry.type, 'service.create');
      expect(entry.payload['name'], 'Corte');
      expect(entry.payload.containsKey('isActive'), false);
    });

    test('nombre repetido (sin mayúsculas) → DuplicateServiceNameFailure',
        () async {
      expect(
          leftOf(await services
              .createService(newService.copyWith(name: 'CEJAS EN HILO'))),
          isA<DuplicateServiceNameFailure>());
      expect(await outbox(), isEmpty);
    });

    test('edición: solo lo que cambia, también isActive (interruptor)',
        () async {
      final current = rightOf(await GetServicesUseCase(services)(NoParams()))
          .single;
      final edited = rightOf(await UpdateServiceUseCase(services)(
          current.copyWith(isActive: false, price: 50000)));
      expect(edited.isActive, false);
      expect((await outbox()).single.payload,
          {'price': 50000.0, 'isActive': false});
      expect(rightOf(await GetServicesUseCase(services)(NoParams())), isEmpty);
    });

    test('datos inválidos o sin id → sin escribir', () async {
      expect(
          leftOf(await CreateServiceUseCase(services)(
              newService.copyWith(name: ' ', price: -1))),
          isA<InvalidCatalogDataFailure>());
      expect(leftOf(await UpdateServiceUseCase(services)(newService)),
          isA<InvalidCatalogDataFailure>());
      expect(await outbox(), isEmpty);
    });

    test('borrado: sale de la lista y queda service.delete', () async {
      rightOf(await services.deleteService('srv-1'));
      expect(rightOf(await services.getAllServices()).map((s) => s.id),
          ['srv-2']);
      expect((await outbox()).single.type, 'service.delete');
    });

    test('servicios que hace un profesional (7.04): Owner todos; empleada '
        'los asignados y activos', () async {
      await DocumentStore.put(db, CatalogDocs.services, 'srv-3',
          {...backendService(id: 'srv-3', name: 'Lifting'), 'isActive': true});
      await DocumentStore.put(db, SharedDocs.users, 'owner-1', {
        'id': 'owner-1',
        'roles': [
          {'name': 'Owner'}
        ],
      });
      await DocumentStore.put(db, SharedDocs.users, 'emp-1', {
        'id': 'emp-1',
        'roles': [
          {'name': 'Employee'}
        ],
      });
      for (final (id, service, active) in [
        ('us-1', 'srv-1', true),
        ('us-2', 'srv-3', false),
        ('us-3', 'srv-2', true), // servicio desactivado
      ]) {
        await DocumentStore.put(db, SharedDocs.userServices, id, {
          'id': id,
          'userId': 'emp-1',
          'serviceId': service,
          'isActive': active,
        });
      }
      final useCase = GetServicesOfferedByUseCase(services);
      expect(rightOf(await useCase('owner-1')).map((s) => s.id),
          ['srv-1', 'srv-3']);
      expect(rightOf(await useCase('emp-1')).map((s) => s.id), ['srv-1']);
    });
  });

  group('Mis servicios (D-27)', () {
    Future<void> seedEmployee() async {
      await DocumentStore.put(db, SharedDocs.users, 'user-1', {
        'id': 'user-1',
        'roles': [
          {'name': 'Employee'}
        ],
      });
      await DocumentStore.put(db, SharedDocs.userServices, 'us-1', {
        'id': 'us-1',
        'userId': 'user-1',
        'serviceId': 'srv-1',
        'isActive': true,
        'commissionPercentage': '45.00',
      });
    }

    test('con conexión manda el servidor (% efectivo de /auth/me/services)',
        () async {
      final remote = _FakeServicesRemote(() async => [
            MyServiceModel.fromJson({
              'id': 'srv-1',
              'name': 'Cejas en hilo',
              'duration': 30,
              'price': 20000,
              'color': '#ff0000',
              'category': {'id': 'cat-1', 'name': 'Cejas'},
              'commission_percentage': 40,
            }),
          ]);
      final repo = ServicesRepositoryImpl(
          OfflineStore(databases: databases), remote: remote);
      final mine = rightOf(await GetMyServicesUseCase(repo)(NoParams()));
      expect(mine.single.service.name, 'Cejas en hilo');
      expect(mine.single.service.category?.name, 'Cejas');
      expect(mine.single.commissionPercentage, 40);
      expect(mine.single.commission, 8000);
    });

    test('sin conexión: lo asignado en el teléfono con su excepción', () async {
      await seedEmployee();
      final repo = ServicesRepositoryImpl(OfflineStore(databases: databases),
          remote: _FakeServicesRemote(() async => throw offlineError()));
      final mine = rightOf(await repo.getMyServices());
      expect(mine.map((m) => (m.service.id, m.commissionPercentage)),
          [('srv-1', 45.0)]);
    });

    test('sin conexión y sin excepción: el % queda sin saber (null)',
        () async {
      await seedEmployee();
      await DocumentStore.put(db, SharedDocs.userServices, 'us-1', {
        'id': 'us-1',
        'userId': 'user-1',
        'serviceId': 'srv-1',
        'isActive': true,
        'commissionPercentage': null,
      });
      final mine = rightOf(await services.getMyServices());
      expect(mine.single.commissionPercentage, isNull);
      expect(mine.single.commission, isNull);
    });

    test('otro error del servidor no se tapa con lo local', () async {
      final repo = ServicesRepositoryImpl(OfflineStore(databases: databases),
          remote: _FakeServicesRemote(() async => throw DioException(
              requestOptions: RequestOptions(path: '/auth/me/services'),
              response: Response(
                  requestOptions: RequestOptions(path: '/auth/me/services'),
                  statusCode: 403,
                  data: {'statusCode': 403, 'code': 'FORBIDDEN'}),
              type: DioExceptionType.badResponse)));
      expect(leftOf(await repo.getMyServices()), isA<ForbiddenFailure>());
    });
  });

  group('categorías', () {
    test('todas con serviceCount local', () async {
      final list = rightOf(await categories.getCategories());
      expect(list.map((c) => (c.name, c.serviceCount)),
          [('Cejas', 2), ('Pestañas', 0)]);
    });

    test('alta, edición (solo lo que cambia) y estado', () async {
      final created = rightOf(await CreateCategoryUseCase(categories)(
          const CategoryParams(name: ' Uñas ')));
      expect(created.name, 'Uñas');
      rightOf(await UpdateCategoryUseCase(categories)(UpdateCategoryParams(
          id: created.id, name: 'Uñas', description: ' acrílicas ')));
      rightOf(await UpdateCategoryStatusUseCase(categories)(
          UpdateCategoryStatusParams(id: created.id, isActive: false)));
      final entries = await outbox();
      expect(entries.map((e) => e.type),
          ['category.create', 'category.update', 'category.update']);
      expect(entries[1].payload, {'description': 'acrílicas'});
      expect(entries[2].payload, {'isActive': false});
    });

    test('nombre repetido, o borrar una con servicios → failures locales',
        () async {
      expect(leftOf(await categories.createCategory(name: 'cejas')),
          isA<DuplicateCategoryNameFailure>());
      expect(leftOf(await DeleteCategoryUseCase(categories)('cat-1')),
          isA<CategoryHasServicesFailure>());
      rightOf(await DeleteCategoryUseCase(categories)('cat-2'));
      expect((await outbox()).single.type, 'category.delete');
    });
  });

  group('sincronización', () {
    test('handler: la bajada guarda; un rechazo vuelve a la versión del '
        'servidor', () async {
      final server = FakeSyncServer();
      server.forced['service.update'] = (mid) => MutationResult(
          mutationId: mid,
          status: MutationStatus.rejected,
          code: 'FORBIDDEN',
          message: 'Solo el dueño');
      final engine = SyncEngine(
          databases: databases, api: server, handlers: CatalogSync.handlers());
      final current = rightOf(await services.getAllServices()).first;
      rightOf(await services.updateService(current.copyWith(price: 1)));
      expect(rightOf(await services.getAllServices()).first.price, 1);

      await engine.syncNow();
      expect(rightOf(await services.getAllServices()).first.price, 45000,
          reason: 'vuelve a la copia del servidor');
      expect((await outbox()).single.status, OutboxStatus.rejected);
      await engine.dispose();
    });

    test('un alta rechazada desaparece de local (no existe en el servidor)',
        () async {
      final server = FakeSyncServer();
      server.forced['category.create'] = (mid) => MutationResult(
          mutationId: mid,
          status: MutationStatus.rejected,
          code: 'VALIDATION_ERROR');
      final engine = SyncEngine(
          databases: databases, api: server, handlers: CatalogSync.handlers());
      final created =
          rightOf(await categories.createCategory(name: 'Nueva'));
      await engine.syncNow();
      expect(
          rightOf(await categories.getCategories()).map((c) => c.id),
          isNot(contains(created.id)));
      await engine.dispose();
    });
  });

  group('cobertura recuperada (10.02b → local): rechazos del servidor', () {
    Future<SyncEngine> engineWith(String type, String code,
        {String? message}) async {
      final server = FakeSyncServer()
        ..forced[type] = (mid) => MutationResult(
            mutationId: mid,
            status: MutationStatus.rejected,
            code: code,
            message: message);
      return SyncEngine(
          databases: databases, api: server, handlers: CatalogSync.handlers());
    }

    test('403 de una empleada al cambiar una categoría: vuelve a la del '
        'servidor y queda el motivo', () async {
      final engine = await engineWith('category.update', 'FORBIDDEN',
          message: 'No tienes permiso para realizar esta acción');
      rightOf(await categories.updateCategoryStatus(id: 'cat-1', isActive: false));
      await engine.syncNow();
      expect(
          rightOf(await categories.getCategories())
              .firstWhere((c) => c.id == 'cat-1')
              .isActive,
          true);
      expect((await outbox()).single.message,
          'No tienes permiso para realizar esta acción');
      await engine.dispose();
    });

    test('409 CONFLICT al borrar (otro dispositivo le puso servicios): la '
        'categoría vuelve', () async {
      final engine = await engineWith('category.delete', 'CONFLICT');
      rightOf(await categories.deleteCategory('cat-2'));
      expect(rightOf(await categories.getCategories()).map((c) => c.id),
          ['cat-1']);
      await engine.syncNow();
      expect(rightOf(await categories.getCategories()).map((c) => c.id),
          ['cat-1', 'cat-2']);
      await engine.dispose();
    });

    test('nombre repetido creado en otro dispositivo (409 CONFLICT): el alta '
        'local desaparece y queda el motivo', () async {
      final engine = await engineWith('service.create', 'CONFLICT',
          message: 'Ya existe un servicio con ese nombre');
      final created = rightOf(await services.createService(newService));
      await engine.syncNow();
      expect(rightOf(await services.getAllServices()).map((s) => s.id),
          isNot(contains(created.id)));
      final entry = (await outbox()).single;
      expect(entry.status, OutboxStatus.rejected);
      expect(entry.message, 'Ya existe un servicio con ese nombre');
      await engine.dispose();
    });
  });

  group('días de mantenimiento (Fase 11)', () {
    test('alta con días: van en service.create; sin días, no', () async {
      rightOf(await CreateServiceUseCase(services)(
          newService.copyWith(maintenanceDays: 21)));
      rightOf(await CreateServiceUseCase(services)(
          newService.copyWith(name: 'Otro')));
      final entries = await outbox();
      expect(entries.first.payload['maintenanceDays'], 21);
      expect(entries.last.payload.containsKey('maintenanceDays'), false);
      expect(
          rightOf(await services.getAllServices())
              .firstWhere((s) => s.name == 'Corte')
              .maintenanceDays,
          21);
    });

    test('editar: solo si cambia; quitarlos envía null', () async {
      final current = rightOf(await services.getAllServices()).first;
      final withDays = rightOf(await services
          .updateService(current.copyWith(maintenanceDays: 30)));
      expect((await outbox()).single.payload, {'maintenanceDays': 30});
      rightOf(await services
          .updateService(withDays.copyWith(clearMaintenanceDays: true)));
      expect((await outbox()).last.payload, {'maintenanceDays': null});
      expect(rightOf(await services.getAllServices()).first.maintenanceDays,
          isNull);
    });

    test('fuera de 1–365 → InvalidCatalogDataFailure sin escribir', () async {
      for (final days in [0, 366]) {
        expect(
            leftOf(await CreateServiceUseCase(services)(
                newService.copyWith(maintenanceDays: days))),
            isA<InvalidCatalogDataFailure>());
      }
      expect(await outbox(), isEmpty);
    });

    test('editar un servicio desactivado conservando su estado no lo '
        'reactiva', () async {
      final inactive = rightOf(await services.getAllServices())
          .firstWhere((s) => !s.isActive);
      rightOf(await services.updateService(inactive.copyWith(price: 1)));
      expect((await outbox()).single.payload, {'price': 1.0});
    });
  });
}

class _FakeServicesRemote implements ServicesRemoteDataSource {
  final Future<List<MyService>> Function() _mine;

  _FakeServicesRemote(this._mine);

  @override
  Future<List<MyService>> getMyServices() => _mine();
}
