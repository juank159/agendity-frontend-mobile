import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/di/session_scope.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/entities/service_price_type.dart';
import 'package:login_signup/features/services/domain/failures/services_failures.dart';
import 'package:login_signup/features/services/domain/repositories/categories_repository.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';
import 'package:login_signup/features/services/domain/usecases/create_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/create_service_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/delete_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_categories_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_status_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_usecase.dart';
import 'package:login_signup/features/services/presentation/bindings/services_binding.dart';
import 'package:login_signup/features/services/presentation/controller/catalog_access.dart';
import 'package:login_signup/features/services/presentation/controller/categories_controller.dart';
import 'package:login_signup/features/services/presentation/controller/new_category_controller.dart';
import 'package:login_signup/features/services/presentation/controller/new_service_controller.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';
import 'package:login_signup/features/services/presentation/screen/categories_screen.dart';
import 'package:login_signup/features/services/presentation/screen/new_category_screen.dart';
import 'package:login_signup/features/services/presentation/screen/new_service_screen.dart';
import 'package:login_signup/features/services/presentation/screen/services_screen.dart';
import 'package:login_signup/features/services/presentation/widgets/color_picker.dart';
import 'package:login_signup/shared/controller/session_controller.dart';

import '../../core/session/memory_token_store.dart';

/// Repositorios falsos: pantallas, controllers y use cases son los reales.
class FakeServicesRepository implements ServicesRepository {
  Either<Failure, List<ServiceEntity>> listResult = const Right([]);
  Either<Failure, ServiceEntity>? createResult;
  final created = <ServiceEntity>[];
  int listCalls = 0;

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices() async {
    listCalls++;
    return listResult;
  }

  @override
  Future<Either<Failure, ServiceEntity>> createService(
      ServiceEntity service) async {
    created.add(service);
    return createResult ?? Right(service.copyWith(id: 'srv-new'));
  }

  @override
  Future<Either<Failure, ServiceEntity>> updateService(
          ServiceEntity service) async =>
      Right(service);

  @override
  Future<Either<Failure, Unit>> deleteService(String id) async =>
      const Right(unit);
}

class FakeCategoriesRepository implements CategoriesRepository {
  Either<Failure, List<CategoryEntity>> listResult = const Right([]);
  Either<Failure, Unit> deleteResult = const Right(unit);
  Either<Failure, CategoryEntity>? createResult;
  final deleted = <String>[];

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async =>
      listResult;

  @override
  Future<Either<Failure, CategoryEntity>> createCategory(
          {required String name, String description = ''}) async =>
      createResult ?? Right(CategoryEntity(id: 'cat-new', name: name));

  @override
  Future<Either<Failure, CategoryEntity>> updateCategory(
          {required String id,
          required String name,
          String description = ''}) async =>
      Right(CategoryEntity(id: id, name: name, description: description));

  @override
  Future<Either<Failure, CategoryEntity>> updateCategoryStatus(
          {required String id, required bool isActive}) async =>
      Right(CategoryEntity(id: id, name: 'x', isActive: isActive));

  @override
  Future<Either<Failure, Unit>> deleteCategory(String id) async {
    deleted.add(id);
    return deleteResult;
  }
}

const nails = CategoryEntity(id: 'cat-1', name: 'Uñas');
const brows = CategoryEntity(id: 'cat-2', name: 'Cejas');
const manicure = ServiceEntity(
  id: 'srv-1',
  name: 'Manicure',
  price: 25000,
  duration: 45,
  categoryId: 'cat-1',
  category: nails,
);

void main() {
  late FakeServicesRepository services;
  late FakeCategoriesRepository categories;

  setUp(() {
    Get.testMode = true;
    services = FakeServicesRepository();
    categories = FakeCategoriesRepository();
  });
  tearDown(Get.reset);

  void signInAs(String role) {
    final store = MemoryTokenStore();
    final session = SessionController(SessionService(
      tokenStore: store,
      repository: SessionRepository(store),
    ));
    session.session.value =
        Session(token: 't-$role', userId: 'u1', roles: [role]);
    Get.put<SessionController>(session, permanent: true);
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(GetMaterialApp(
      theme: ThemeConfig.lightTheme,
      home: home,
    ));
    await tester.pumpAndSettle();
  }

  /// Deja que el snackbar se cierre (si no, el test termina con timers).
  Future<void> expireSnackbar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  ServicesController putServicesController() => Get.put(ServicesController(
        getServicesUseCase: GetServicesUseCase(services),
        getCategoriesUseCase: GetCategoriesUseCase(categories),
      ));

  CategoriesController putCategoriesController() =>
      Get.put(CategoriesController(
        getCategoriesUseCase: GetCategoriesUseCase(categories),
        updateCategoryUseCase: UpdateCategoryUseCase(categories),
        updateCategoryStatusUseCase: UpdateCategoryStatusUseCase(categories),
        deleteCategoryUseCase: DeleteCategoryUseCase(categories),
      ));

  group('ServicesScreen', () {
    testWidgets('un Left muestra el error con reintento, no una lista vacía',
        (tester) async {
      signInAs('Owner');
      services.listResult =
          const Left(NetworkFailure(message: 'Sin conexión a internet'));
      putServicesController();
      await pump(tester, const ServicesScreen());

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Sin conexión a internet'), findsOneWidget);
      expect(find.text('Aún no hay servicios'), findsNothing);

      services.listResult = const Right([manicure]);
      await tapText(tester, 'Reintentar');

      expect(find.byType(ErrorState), findsNothing);
      expect(find.text('Manicure'), findsOneWidget);
      expect(find.text('Uñas'), findsOneWidget);
      expect(services.listCalls, 2);
    });

    testWidgets('el Employee ve los servicios en solo lectura',
        (tester) async {
      signInAs('Employee');
      services.listResult = const Right([manicure]);
      putServicesController();
      await pump(tester, const ServicesScreen());

      expect(find.text('Manicure'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      final tile = tester.widget<ListTile>(find.ancestor(
          of: find.text('Manicure'), matching: find.byType(ListTile)));
      expect(tile.onTap, isNull);
      // Las categorías siguen accesibles (en solo lectura).
      expect(find.byTooltip('Categorías'), findsOneWidget);
    });

    testWidgets('el Owner tiene el botón de crear y puede abrir cada servicio',
        (tester) async {
      signInAs('Owner');
      services.listResult = const Right([manicure]);
      putServicesController();
      await pump(tester, const ServicesScreen());

      expect(find.byType(FloatingActionButton), findsOneWidget);
      final tile = tester.widget<ListTile>(find.ancestor(
          of: find.text('Manicure'), matching: find.byType(ListTile)));
      expect(tile.onTap, isNotNull);
    });
  });

  group('CategoriesScreen', () {
    testWidgets('borrar una categoría con servicios muestra el aviso',
        (tester) async {
      signInAs('Owner');
      // Sin `serviceCount`: lo descubre el backend.
      categories.listResult = const Right([nails]);
      categories.deleteResult = const Left(CategoryHasServicesFailure());
      putCategoriesController();
      await pump(tester, const CategoriesScreen());

      await tester.tap(find.byTooltip('Más acciones'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Eliminar');
      expect(find.text('¿Eliminar categoría?'), findsOneWidget);
      await tapText(tester, 'Eliminar');

      expect(categories.deleted, ['cat-1']);
      expect(find.text(CatalogAccess.categoryHasServicesMessage),
          findsOneWidget);
      await tapText(tester, 'Entendido');
      expect(find.text('Uñas'), findsOneWidget);
    });

    testWidgets('si ya se sabe que tiene servicios, avisa sin llamar al backend',
        (tester) async {
      signInAs('Owner');
      categories.listResult =
          const Right([CategoryEntity(id: 'cat-1', name: 'Uñas', serviceCount: 3)]);
      putCategoriesController();
      await pump(tester, const CategoriesScreen());

      expect(find.textContaining('3 servicios'), findsOneWidget);
      await tester.tap(find.byTooltip('Más acciones'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Eliminar');

      expect(categories.deleted, isEmpty);
      expect(find.text(CatalogAccess.categoryHasServicesMessage),
          findsOneWidget);
    });

    testWidgets('borrar una categoría vacía la quita de la lista',
        (tester) async {
      signInAs('Owner');
      categories.listResult = const Right(
          [CategoryEntity(id: 'cat-1', name: 'Uñas', serviceCount: 0), brows]);
      putCategoriesController();
      await pump(tester, const CategoriesScreen());

      await tester.tap(find.byTooltip('Más acciones').first);
      await tester.pumpAndSettle();
      await tapText(tester, 'Eliminar');
      await tapText(tester, 'Eliminar');

      expect(categories.deleted, ['cat-1']);
      expect(find.text('Uñas'), findsNothing);
      expect(find.text('Cejas'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('el Employee ve las categorías sin acciones', (tester) async {
      signInAs('Employee');
      categories.listResult = const Right([nails, brows]);
      putCategoriesController();
      await pump(tester, const CategoriesScreen());

      expect(find.text('Uñas'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(find.byTooltip('Más acciones'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('un Left muestra el error con reintento', (tester) async {
      signInAs('Employee');
      categories.listResult = const Left(ServerFailure(message: 'Falló'));
      putCategoriesController();
      await pump(tester, const CategoriesScreen());

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('Formulario de servicio', () {
    /// Abre [screen] desde una pantalla base y devuelve el resultado.
    Future<List<Object?>> openFrom(WidgetTester tester, Widget screen) async {
      final results = <Object?>[];
      await pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(await Get.to(() => screen)),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('guarda el tipo de precio como enum y el color como hex',
        (tester) async {
      signInAs('Owner');
      categories.listResult = const Right([nails]);
      Get.put(NewServiceController(
        getCategoriesUseCase: GetCategoriesUseCase(categories),
        createServiceUseCase: CreateServiceUseCase(services),
      ));
      final results = await openFrom(tester, const NewServiceScreen());

      await tester.enterText(
          find.widgetWithText(TextField, 'Nombre del servicio'), 'Uñas acrílicas');
      await tester.enterText(find.widgetWithText(TextField, 'Precio'), '80000');
      await tapText(tester, ServicePriceType.variable.apiValue);
      final green = find.byKey(const ValueKey('service-color-#4caf50'));
      await tester.ensureVisible(green);
      await tester.pumpAndSettle();
      await tester.tap(green);
      await tester.pumpAndSettle();
      await tapText(tester, 'Guardar');

      expect(services.created, hasLength(1));
      final saved = services.created.single;
      expect(saved.name, 'Uñas acrílicas');
      expect(saved.price, 80000);
      expect(saved.priceType, ServicePriceType.variable);
      expect(saved.color, '#4caf50');
      expect(saved.categoryId, 'cat-1'); // única categoría: elegida sola
      expect(results, [true]);
      await expireSnackbar(tester);
    });

    testWidgets('nombre duplicado: avisa y se queda en el formulario',
        (tester) async {
      signInAs('Owner');
      categories.listResult = const Right([nails]);
      services.createResult = const Left(DuplicateServiceNameFailure());
      Get.put(NewServiceController(
        getCategoriesUseCase: GetCategoriesUseCase(categories),
        createServiceUseCase: CreateServiceUseCase(services),
      ));
      final results = await openFrom(tester, const NewServiceScreen());

      await tester.enterText(
          find.widgetWithText(TextField, 'Nombre del servicio'), 'Manicure');
      await tester.enterText(find.widgetWithText(TextField, 'Precio'), '25000');
      await tapText(tester, 'Guardar');

      expect(find.text(DuplicateServiceNameFailure.defaultMessage),
          findsOneWidget);
      expect(find.byType(NewServiceScreen), findsOneWidget);
      expect(results, isEmpty);
      await expireSnackbar(tester);
    });

    testWidgets('precio vacío: no llama al backend', (tester) async {
      signInAs('Owner');
      categories.listResult = const Right([nails]);
      Get.put(NewServiceController(
        getCategoriesUseCase: GetCategoriesUseCase(categories),
        createServiceUseCase: CreateServiceUseCase(services),
      ));
      await openFrom(tester, const NewServiceScreen());

      await tester.enterText(
          find.widgetWithText(TextField, 'Nombre del servicio'), 'Corte');
      await tapText(tester, 'Guardar');

      expect(services.created, isEmpty);
      expect(find.text('Escribe el precio del servicio (solo números).'),
          findsOneWidget);
      await expireSnackbar(tester);
    });
  });

  testWidgets('categoría con nombre duplicado: avisa y no cierra',
      (tester) async {
    signInAs('Owner');
    categories.createResult = const Left(DuplicateCategoryNameFailure());
    Get.put(NewCategoryController(
        createCategoryUseCase: CreateCategoryUseCase(categories)));
    await pump(tester, const NewCategoryScreen());

    await tester.enterText(
        find.widgetWithText(TextField, 'Nombre de la categoría'), 'Uñas');
    await tapText(tester, 'Crear categoría');

    expect(find.text(DuplicateCategoryNameFailure.defaultMessage),
        findsOneWidget);
    expect(find.byType(NewCategoryScreen), findsOneWidget);
    await expireSnackbar(tester);
  });

  test('registro único de ServicesController: fenix y recarga al recrearse',
      () async {
    Get.put(GetServicesUseCase(services));
    Get.put(GetCategoriesUseCase(categories));
    ServicesBinding.registerController();
    ServicesBinding.registerController(); // la llaman varias rutas: no duplica

    final first = Get.find<ServicesController>();
    await first.loadServices();
    expect(services.listCalls, 1); // onInit + loadServices = una petición

    deleteSessionController<ServicesController>(); // logout
    final second = Get.find<ServicesController>();
    expect(identical(first, second), isFalse);
    await second.loadServices();
    expect(services.listCalls, 2);
  });

  test('colorToHex/colorFromHex', () {
    expect(colorToHex(const Color(0xFF4CAF50)), '#4caf50');
    expect(colorFromHex('#4caf50'), const Color(0xFF4CAF50));
    expect(colorFromHex('#fff'), const Color(0xFFFFFFFF));
    expect(colorToHex(colorFromHex('rojo')), ServiceEntity.defaultColor);
  });
}
