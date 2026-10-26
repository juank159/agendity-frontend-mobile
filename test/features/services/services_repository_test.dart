import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/data/datasources/categories_remote_datasource.dart';
import 'package:login_signup/features/services/data/datasources/services_remote_datasource.dart';
import 'package:login_signup/features/services/data/repositories/categories_repository_impl.dart';
import 'package:login_signup/features/services/data/repositories/services_repository_impl.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/failures/services_failures.dart';
import 'package:login_signup/features/services/domain/usecases/create_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/create_service_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/delete_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_status_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_service_usecase.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';
import 'services_models_test.dart' show backendCategory, backendService;

Failure? leftOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => null);

T rightOf<T>(Either<Failure, T> result) =>
    result.getOrElse(() => throw StateError('Left: ${leftOf(result)}'));

const newService = ServiceEntity(
  name: '  Corte  ',
  price: 30000,
  duration: 30,
  categoryId: 'cat-1',
  color: '#1c94f4',
);

ResponseBody conflict(String code, String message) =>
    jsonBody(409, {'statusCode': 409, 'code': code, 'message': message});

ResponseBody forbidden() => jsonBody(403, {
      'statusCode': 403,
      'code': 'FORBIDDEN',
      'message': 'No tienes permiso para realizar esta acción',
    });

ResponseBody validation() => jsonBody(400, {
      'statusCode': 400,
      'code': 'VALIDATION_ERROR',
      'message': 'price must not be less than 0\nduration must be a number',
      'details': ['price must not be less than 0', 'duration must be a number'],
    });

void main() {
  late FakeHttpClientAdapter adapter;
  late Dio dio;

  setUp(() {
    adapter = FakeHttpClientAdapter((_) => jsonBody(200, []));
    dio = buildApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: MemoryTokenStore('jwt'),
      httpClientAdapter: adapter,
      retryDelay: (_) => Duration.zero,
      enableLogs: false,
    );
  });

  group('ServicesRepositoryImpl (Dio api + adaptador falso)', () {
    late ServicesRepositoryImpl repository;

    setUp(() =>
        repository = ServicesRepositoryImpl(ServicesRemoteDataSourceImpl(dio)));

    test('GET /services: entidades, token del núcleo y sin tenant-id',
        () async {
      adapter.handler = (_) => jsonBody(200, [backendService()]);
      final services = rightOf(await repository.getServices());
      expect(services.single.price, 45000.0);
      expect(services.single.category!.id, 'cat-1');

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/services');
      expect(request.headers['Authorization'], 'Bearer jwt');
      expect(request.headers.containsKey('tenant-id'), false);
    });

    test('POST /services (201): envía el DTO y devuelve el creado', () async {
      adapter.handler =
          (_) => jsonBody(201, backendService(withCategory: false));
      final created = rightOf(await repository.createService(newService));
      expect(created.id, 'srv-1');
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/services');
      expect((request.data as Map)['categoryId'], 'cat-1');
      expect((request.data as Map).containsKey('isActive'), false);
    });

    test('PATCH /services/:id (200) con el id de la entidad', () async {
      adapter.handler = (_) => jsonBody(200, backendService());
      final result = await repository
          .updateService(newService.copyWith(id: 'srv-1', price: 35000));
      expect(result.isRight(), true);
      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.uri.path, '/api/services/srv-1');
      expect((request.data as Map)['price'], 35000.0);
    });

    test('DELETE /services/:id (200 sin cuerpo) → Right(unit)', () async {
      adapter.handler = (_) => ResponseBody.fromString('', 200);
      expect(await repository.deleteService('srv-1'), const Right(unit));
      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.uri.path, '/api/services/srv-1');
    });

    test('409 nombre repetido (CONFLICT) → DuplicateServiceNameFailure',
        () async {
      adapter.handler = (_) => conflict(
          'CONFLICT', 'Ya existe un servicio con ese nombre en tu negocio');
      for (final result in [
        await repository.createService(newService),
        await repository.updateService(newService.copyWith(id: 'srv-1')),
      ]) {
        final failure = leftOf(result);
        expect(failure, isA<DuplicateServiceNameFailure>());
        expect(failure, isA<ConflictFailure>());
        expect(failure!.message,
            'Ya existe un servicio con ese nombre en tu negocio');
        expect(failure.statusCode, 409);
      }
    });

    test('403 del Employee al escribir → ForbiddenFailure', () async {
      adapter.handler = (_) => forbidden();
      expect(leftOf(await repository.createService(newService)),
          isA<ForbiddenFailure>());
      expect(
          leftOf(
              await repository.updateService(newService.copyWith(id: 'srv-1'))),
          isA<ForbiddenFailure>());
      expect(leftOf(await repository.deleteService('srv-1')),
          isA<ForbiddenFailure>());
    });

    test('400 VALIDATION_ERROR → ValidationFailure con details', () async {
      adapter.handler = (_) => validation();
      final failure = leftOf(await repository.createService(newService));
      expect(failure, isA<ValidationFailure>());
      expect(failure!.details,
          ['price must not be less than 0', 'duration must be a number']);
    });

    test('sin red: GET reintenta y da NetworkFailure; POST no reintenta',
        () async {
      adapter.handler = connectionError;
      expect(leftOf(await repository.getServices()), isA<NetworkFailure>());
      expect(adapter.requests, hasLength(4));
      adapter.requests.clear();
      expect(leftOf(await repository.createService(newService)),
          isA<NetworkFailure>());
      expect(adapter.requests, hasLength(1));
    });

    // Hallazgo crítico de la revisión inicial: con el Dio viejo
    // (`validateStatus < 600`) crear, editar y borrar no miraban el estado y
    // un 4xx/5xx se informaba como éxito.
    test('falsos éxitos corregidos: 4xx/5xx al escribir → Left', () async {
      for (final status in [400, 404, 409, 500]) {
        adapter.handler = (_) => jsonBody(status, {'statusCode': status});
        expect(leftOf(await repository.createService(newService)), isNotNull,
            reason: 'POST $status');
        expect(
            leftOf(await repository
                .updateService(newService.copyWith(id: 'srv-1'))),
            isNotNull,
            reason: 'PATCH $status');
        expect(leftOf(await repository.deleteService('srv-1')), isNotNull,
            reason: 'DELETE $status');
      }
      adapter.handler = (_) => textBody(502, '<html>Bad gateway</html>');
      final failure = leftOf(await repository.createService(newService));
      expect(failure, isA<ServerFailure>());
      expect(failure!.message, ServerFailure.defaultMessage);
    });

    test('respuesta que no es lista → ServerFailure, sin excepción', () async {
      adapter.handler = (_) => jsonBody(200, {'unexpected': true});
      expect(leftOf(await repository.getServices()), isA<ServerFailure>());
    });
  });

  group('CategoriesRepositoryImpl (Dio api + adaptador falso)', () {
    late CategoriesRepositoryImpl repository;

    setUp(() => repository =
        CategoriesRepositoryImpl(CategoriesRemoteDataSourceImpl(dio)));

    test('GET /categories → entidades con serviceCount', () async {
      adapter.handler = (_) => jsonBody(200, [
            backendCategory(services: [backendService(withCategory: false)]),
            backendCategory(id: 'cat-2', name: 'Uñas', services: []),
          ]);
      final categories = rightOf(await repository.getCategories());
      expect(categories.map((c) => c.serviceCount), [1, 0]);
      expect(adapter.requests.single.uri.path, '/api/categories');
    });

    test('POST /categories (201) con name y description', () async {
      adapter.handler = (_) => jsonBody(201, backendCategory(name: 'Uñas'));
      final created = rightOf(await repository.createCategory(
          name: 'Uñas', description: 'Manicure'));
      expect(created.name, 'Uñas');
      expect(adapter.requests.single.data,
          {'name': 'Uñas', 'description': 'Manicure'});
    });

    test('PATCH /categories/:id: editar y cambiar estado (parcial)', () async {
      adapter.handler = (_) => jsonBody(200, backendCategory(isActive: false));
      rightOf(await repository.updateCategory(
          id: 'cat-1', name: 'Cejas', description: ''));
      final status = rightOf(
          await repository.updateCategoryStatus(id: 'cat-1', isActive: false));
      expect(status.isActive, false);

      expect(adapter.requests.map((r) => '${r.method} ${r.uri.path}'),
          ['PATCH /api/categories/cat-1', 'PATCH /api/categories/cat-1']);
      expect(adapter.requests.first.data, {'name': 'Cejas', 'description': ''});
      // Antes: GET + PATCH con todo; ahora un solo PATCH con el estado.
      expect(adapter.requests.last.data, {'isActive': false});
    });

    test('DELETE /categories/:id (200) → Right(unit)', () async {
      adapter.handler = (_) => ResponseBody.fromString('', 200);
      expect(await repository.deleteCategory('cat-1'), const Right(unit));
      expect(adapter.requests.single.method, 'DELETE');
    });

    test('409 CATEGORY_HAS_SERVICES → CategoryHasServicesFailure', () async {
      const message = 'No se puede eliminar la categoría porque tiene '
          'servicios. Muévelos a otra categoría o elimínalos primero.';
      adapter.handler = (_) => conflict('CATEGORY_HAS_SERVICES', message);
      final failure = leftOf(await repository.deleteCategory('cat-1'));
      expect(failure, isA<CategoryHasServicesFailure>());
      expect(failure, isA<ConflictFailure>());
      expect(failure!.code, ApiErrorCode.categoryHasServices);
      expect(failure.message, message);
    });

    test('409 CONFLICT al borrar (FK RESTRICT) → CategoryHasServicesFailure',
        () async {
      adapter.handler = (_) => conflict('CONFLICT', 'Conflicto');
      expect(leftOf(await repository.deleteCategory('cat-1')),
          isA<CategoryHasServicesFailure>());
    });

    test('409 nombre repetido al crear o editar → DuplicateCategoryName',
        () async {
      adapter.handler = (_) => conflict('CONFLICT',
          "Ya tienes una categoría con el nombre 'Cejas'. Por favor, usa un nombre diferente.");
      expect(leftOf(await repository.createCategory(name: 'Cejas')),
          isA<DuplicateCategoryNameFailure>());
      expect(
          leftOf(await repository.updateCategory(id: 'cat-2', name: 'Cejas')),
          isA<DuplicateCategoryNameFailure>());
    });

    test('403 del Employee al escribir → ForbiddenFailure', () async {
      adapter.handler = (_) => forbidden();
      expect(leftOf(await repository.createCategory(name: 'X')),
          isA<ForbiddenFailure>());
      expect(
          leftOf(await repository.updateCategoryStatus(
              id: 'cat-1', isActive: true)),
          isA<ForbiddenFailure>());
      expect(leftOf(await repository.deleteCategory('cat-1')),
          isA<ForbiddenFailure>());
    });

    test('400 VALIDATION_ERROR → ValidationFailure con details', () async {
      adapter.handler = (_) => validation();
      final failure = leftOf(await repository.createCategory(name: 'X'));
      expect(failure, isA<ValidationFailure>());
      expect(failure!.details, hasLength(2));
    });

    test('sin red → NetworkFailure', () async {
      adapter.handler = connectionError;
      expect(leftOf(await repository.getCategories()), isA<NetworkFailure>());
      expect(leftOf(await repository.deleteCategory('cat-1')),
          isA<NetworkFailure>());
    });

    test('falso éxito corregido: 500 al cambiar el estado → Left', () async {
      adapter.handler = (_) => jsonBody(500, {'statusCode': 500});
      expect(
          leftOf(await repository.updateCategoryStatus(
              id: 'cat-1', isActive: false)),
          isA<ServerFailure>());
    });
  });

  group('Use cases (sobre el repositorio real y el adaptador falso)', () {
    late ServicesRepositoryImpl services;
    late CategoriesRepositoryImpl categories;

    setUp(() {
      services = ServicesRepositoryImpl(ServicesRemoteDataSourceImpl(dio));
      categories =
          CategoriesRepositoryImpl(CategoriesRemoteDataSourceImpl(dio));
    });

    test('GetServicesUseCase devuelve lo del repositorio', () async {
      adapter.handler = (_) => jsonBody(200, [backendService()]);
      expect(rightOf(await GetServicesUseCase(services)(NoParams())),
          hasLength(1));
    });

    test('CreateServiceUseCase recorta el nombre antes de enviarlo', () async {
      adapter.handler = (_) => jsonBody(201, backendService());
      await CreateServiceUseCase(services)(newService);
      expect((adapter.requests.single.data as Map)['name'], 'Corte');
    });

    test('CreateServiceUseCase: datos inválidos → sin llamar al backend',
        () async {
      final failure = leftOf(await CreateServiceUseCase(services)(
          newService.copyWith(
              name: ' ',
              price: -1,
              duration: 0,
              categoryId: '',
              color: 'red')));
      expect(failure, isA<InvalidCatalogDataFailure>());
      expect(failure, isA<ValidationFailure>());
      expect(failure!.details, hasLength(5));
      expect(adapter.requests, isEmpty);
    });

    test('UpdateServiceUseCase sin id → InvalidCatalogDataFailure', () async {
      final failure = leftOf(await UpdateServiceUseCase(services)(newService));
      expect(failure, isA<InvalidCatalogDataFailure>());
      expect(failure!.message, UpdateServiceUseCase.missingIdMessage);
      expect(adapter.requests, isEmpty);
    });

    test('CreateCategoryUseCase: nombre vacío o > 100 → sin backend', () async {
      final useCase = CreateCategoryUseCase(categories);
      expect(leftOf(await useCase(const CategoryParams(name: '  '))),
          isA<InvalidCatalogDataFailure>());
      expect(leftOf(await useCase(CategoryParams(name: 'x' * 101))),
          isA<InvalidCatalogDataFailure>());
      expect(adapter.requests, isEmpty);
    });

    test('UpdateCategoryUseCase recorta y envía', () async {
      adapter.handler = (_) => jsonBody(200, backendCategory());
      await UpdateCategoryUseCase(categories)(const UpdateCategoryParams(
          id: 'cat-1', name: ' Cejas ', description: ' d '));
      expect(
          adapter.requests.single.data, {'name': 'Cejas', 'description': 'd'});
    });

    test('UpdateCategoryStatus y DeleteCategory delegan', () async {
      adapter.handler = (_) => jsonBody(200, backendCategory());
      expect(
          (await UpdateCategoryStatusUseCase(categories)(
                  const UpdateCategoryStatusParams(
                      id: 'cat-1', isActive: true)))
              .isRight(),
          true);
      adapter.handler =
          (_) => conflict('CATEGORY_HAS_SERVICES', 'No se puede eliminar');
      expect(leftOf(await DeleteCategoryUseCase(categories)('cat-1')),
          isA<CategoryHasServicesFailure>());
    });
  });
}
