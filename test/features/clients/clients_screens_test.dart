import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/client_import_result.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/features/clients/domain/entities/paginated_list.dart';
import 'package:login_signup/features/clients/domain/failures/client_failures.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';
import 'package:login_signup/features/clients/domain/usecases/create_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/delete_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/get_client_by_id_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/get_clients_page_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/import_clients_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/update_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/upload_client_image_usecase.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';
import 'package:login_signup/features/clients/presentation/controller/edit_client_controller.dart';
import 'package:login_signup/features/clients/presentation/controller/new_client_controller.dart';
import 'package:login_signup/features/clients/presentation/screen/clients_screen.dart';
import 'package:login_signup/features/clients/presentation/screen/edit_client_screen.dart';
import 'package:login_signup/features/clients/presentation/screen/new_client_screen.dart';
import 'package:login_signup/shared/controller/session_controller.dart';

import '../../core/session/memory_token_store.dart';

/// Repositorio falso: pantallas, controllers y use cases son los reales.
class FakeClientsRepository implements ClientsRepository {
  Either<Failure, PaginatedList<ClientEntity>> pageResult = Right(page([ana]));
  Either<Failure, ClientEntity> byIdResult = const Right(ana);
  Either<Failure, ClientEntity>? createResult;
  Either<Failure, Unit> deleteResult = const Right(unit);
  Either<Failure, ClientImportResult> importResult =
      const Right(ClientImportResult(requested: 0, imported: 0));

  final created = <ClientEntity>[];
  final deleted = <String>[];
  final importedBatches = <List<ClientEntity>>[];
  int pageCalls = 0;

  @override
  Future<Either<Failure, PaginatedList<ClientEntity>>> getClients(
      ClientsQuery query) async {
    pageCalls++;
    return pageResult;
  }

  @override
  Future<Either<Failure, ClientEntity>> getClientById(String id) async =>
      byIdResult;

  @override
  Future<Either<Failure, ClientEntity>> createClient(
      ClientEntity client) async {
    created.add(client);
    return createResult ?? Right(client.copyWith(id: 'new'));
  }

  @override
  Future<Either<Failure, ClientEntity>> updateClient(
          ClientEntity client) async =>
      Right(client);

  @override
  Future<Either<Failure, Unit>> deleteClient(String id) async {
    deleted.add(id);
    return deleteResult;
  }

  @override
  Future<Either<Failure, ClientImportResult>> importClients(
      List<ClientEntity> clients) async {
    importedBatches.add(clients);
    return importResult;
  }

  @override
  Future<Either<Failure, String>> uploadImage(String filePath) async =>
      const Right('https://img/x.png');
}

PaginatedList<ClientEntity> page(List<ClientEntity> items) => PaginatedList(
      items: items,
      total: items.length,
      page: 1,
      limit: 20,
      totalPages: 1,
      hasNextPage: false,
      hasPrevPage: false,
    );

const ana = ClientEntity(
  id: 'c1',
  name: 'Ana',
  lastname: 'Pérez',
  phone: '3001234567',
  email: 'ana@mail.com',
  address: 'Calle 10 # 5-20',
);

void main() {
  late FakeClientsRepository repo;

  setUpAll(() => initializeDateFormatting('es'));
  setUp(() {
    Get.testMode = true;
    repo = FakeClientsRepository();
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

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  /// Deja que el snackbar se cierre (si no, el test termina con timers).
  Future<void> expireSnackbar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  ClientsController putListController({DeviceContactsReader? contacts}) =>
      Get.put(ClientsController(
        getClientsPageUseCase: GetClientsPageUseCase(repo),
        importClientsUseCase: ImportClientsUseCase(repo),
        readDeviceContacts: contacts ?? () async => const [],
      ));

  EditClientController putEditController() => Get.put(EditClientController(
        getClientByIdUseCase: GetClientByIdUseCase(repo),
        updateClientUseCase: UpdateClientUseCase(repo),
        deleteClientUseCase: DeleteClientUseCase(repo),
        uploadClientImageUseCase: UploadClientImageUseCase(repo),
        clientId: 'c1',
      ));

  group('Lista', () {
    testWidgets('un error se muestra con reintento, no como lista vacía',
        (tester) async {
      signInAs('Owner');
      repo.pageResult =
          const Left(NetworkFailure(message: 'Sin conexión a internet'));
      putListController();
      await pump(tester, const ClientsScreen());

      expect(find.text('Sin conexión a internet'), findsOneWidget);
      expect(find.text('Aún no tienes clientes'), findsNothing);

      repo.pageResult = Right(page([ana]));
      await tapText(tester, 'Reintentar');
      expect(find.text('Ana Pérez'), findsOneWidget);
    });

    testWidgets('import parcial: resumen con importados y rechazados',
        (tester) async {
      signInAs('Employee');
      repo.importResult = const Right(ClientImportResult(
        requested: 2,
        imported: 1,
        rejected: [
          ClientImportRejection(
              name: 'Luis',
              phone: '3009998888',
              reason: 'Teléfono ya registrado en tu negocio'),
        ],
      ));
      putListController(
        contacts: () async => const [
          ClientEntity(name: 'Marta', phone: '3101112222'),
          ClientEntity(name: 'Luis', phone: '300 999 8888'),
          ClientEntity(name: 'Corto', phone: '123'),
        ],
      );
      await pump(tester, const ClientsScreen());

      await tester.tap(find.byTooltip('Agregar cliente'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Importar contactos');

      // El teléfono corto se rechaza en la app; los otros dos van al backend.
      expect(repo.importedBatches.single, hasLength(2));
      expect(find.text('Importación parcial'), findsOneWidget);
      expect(find.text('1 importados, 2 rechazados de 3 contactos.'),
          findsOneWidget);
      expect(
          find.textContaining('Luis: Teléfono ya registrado'), findsOneWidget);
      expect(
          find.textContaining('Corto: El teléfono debe tener'), findsOneWidget);
      await tapText(tester, 'Entendido');
    });
  });

  group('Alta', () {
    testWidgets('teléfono repetido: aviso y se queda en el formulario',
        (tester) async {
      signInAs('Employee');
      repo.createResult = const Left(DuplicateClientPhoneFailure());
      Get.put(NewClientController(
        createClientUseCase: CreateClientUseCase(repo),
        uploadClientImageUseCase: UploadClientImageUseCase(repo),
      ));
      await pump(tester, const NewClientScreen());

      await tester.enterText(find.widgetWithText(TextField, 'Nombre *'), 'Ana');
      await tester.enterText(
          find.widgetWithText(TextField, 'Teléfono móvil *'), '3001234567');
      await tapText(tester, 'Guardar cliente');

      expect(repo.created, hasLength(1));
      expect(find.text('Cliente repetido'), findsOneWidget);
      expect(find.text(DuplicateClientPhoneFailure.defaultMessage),
          findsOneWidget);
      expect(find.text('Nuevo cliente'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('datos inválidos: no llama al backend', (tester) async {
      signInAs('Owner');
      Get.put(NewClientController(
        createClientUseCase: CreateClientUseCase(repo),
        uploadClientImageUseCase: UploadClientImageUseCase(repo),
      ));
      await pump(tester, const NewClientScreen());

      await tester.enterText(
          find.widgetWithText(TextField, 'Teléfono móvil *'), '300');
      await tapText(tester, 'Guardar cliente');

      expect(repo.created, isEmpty);
      expect(find.text('Revisa los datos'), findsOneWidget);
      await expireSnackbar(tester);
    });
  });

  group('Edición', () {
    testWidgets('muestra la dirección y el Owner puede borrar', (tester) async {
      signInAs('Owner');
      putEditController();
      await pump(tester, const EditClientScreen());

      expect(find.text('Calle 10 # 5-20'), findsOneWidget);
      expect(find.text('Eliminar cliente'), findsOneWidget);
    });

    testWidgets('borrar con historial: diálogo de citas o reseñas',
        (tester) async {
      signInAs('Owner');
      repo.deleteResult = const Left(ClientHasHistoryFailure());
      putEditController();
      await pump(tester, const EditClientScreen());

      await tapText(tester, 'Eliminar cliente');
      await tapText(tester, 'Eliminar');

      expect(repo.deleted, ['c1']);
      expect(find.text('No se puede eliminar'), findsOneWidget);
      expect(find.textContaining('tiene citas o reseñas'), findsOneWidget);
      await tapText(tester, 'Entendido');
      expect(find.text('Editar cliente'), findsOneWidget);
    });

    testWidgets('el Employee edita pero no ve "Eliminar"', (tester) async {
      signInAs('Employee');
      putEditController();
      await pump(tester, const EditClientScreen());

      expect(find.text('Guardar cambios'), findsOneWidget);
      expect(find.text('Eliminar cliente'), findsNothing);
      expect(await Get.find<EditClientController>().delete(), isFalse);
      expect(repo.deleted, isEmpty);
    });
  });
}
