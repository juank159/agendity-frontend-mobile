import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/domain/entities/consent_link.dart';
import 'package:login_signup/features/clients/domain/usecases/request_consent_link_usecase.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/repositories/settings_repository.dart';
import 'package:login_signup/features/settings/domain/usecases/get_business_settings_usecase.dart';
import 'package:login_signup/shared/utils/external_link.dart';
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
import 'package:login_signup/features/clients/presentation/controllers/clients_controller.dart';
import 'package:login_signup/features/clients/presentation/controllers/edit_client_controller.dart';
import 'package:login_signup/features/clients/presentation/controllers/new_client_controller.dart';
import 'package:login_signup/features/clients/presentation/screens/clients_screen.dart';
import 'package:login_signup/features/clients/presentation/screens/edit_client_screen.dart';
import 'package:login_signup/features/clients/presentation/screens/new_client_screen.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_search_field.dart';
import 'package:login_signup/shared/widgets/app_sheet.dart';

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
  final queries = <ClientsQuery>[];
  Either<Failure, ConsentLink> consentResult = const Right(
      ConsentLink(path: '/consentimiento/tok-1'));
  final consentRequests = <String>[];

  @override
  Future<Either<Failure, ConsentLink>> requestConsentLink(
      String clientId) async {
    consentRequests.add(clientId);
    return consentResult;
  }

  @override
  Future<Either<Failure, PaginatedList<ClientEntity>>> getClients(
      ClientsQuery query) async {
    pageCalls++;
    queries.add(query);
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
      ClientEntity client) async {
    updated.add(client);
    return Right(client);
  }

  final updated = <ClientEntity>[];

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
    // Los formularios crecieron (consentimiento, mantenimiento: 11.04).
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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

  final opened = <Uri>[];

  EditClientController putEditController() => Get.put(EditClientController(
        requestConsentLinkUseCase: RequestConsentLinkUseCase(repo),
        getBusinessSettingsUseCase:
            GetBusinessSettingsUseCase(_FakeSettings()),
        apiUrl: () => 'http://api.test/api',
        getClientByIdUseCase: GetClientByIdUseCase(repo),
        updateClientUseCase: UpdateClientUseCase(repo),
        deleteClientUseCase: DeleteClientUseCase(repo),
        uploadClientImageUseCase: UploadClientImageUseCase(repo),
        clientId: 'c1',
        openLink: (uri) async {
          opened.add(uri);
          return true;
        },
      ));

  group('Lista', () {
    test('filtro "Sin consentimiento" llega a la consulta', () async {
      signInAs('Owner');
      final c = putListController();
      await Future<void>.delayed(Duration.zero);
      c.applyWithoutConsent(true);
      await Future<void>.delayed(Duration.zero);
      expect(repo.queries.last.withoutConsent, isTrue);
      expect(c.hasActiveFilters, isTrue);
      c.clearAllFilters();
      await Future<void>.delayed(Duration.zero);
      expect(repo.queries.last.withoutConsent, isFalse);
    });

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
    testWidgets('consentimiento al crear: la casilla registra true',
        (tester) async {
      signInAs('Employee');
      Get.put(NewClientController(
        createClientUseCase: CreateClientUseCase(repo),
        uploadClientImageUseCase: UploadClientImageUseCase(repo),
      ));
      await pump(tester, const NewClientScreen());
      await tester.enterText(find.widgetWithText(TextField, 'Nombre *'), 'Ana');
      await tester.enterText(
          find.widgetWithText(TextField, 'Teléfono móvil *'), '3001234567');
      await tester.tap(find.byKey(const Key('client-whatsapp-opt-in')));
      await tester.pump();
      await tapText(tester, 'Guardar cliente');
      expect(repo.created.single.whatsappOptIn, isTrue);
      await expireSnackbar(tester);
    });

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

  group('Rediseño (12.06)', () {
    testWidgets(
        'tarjeta: AppAvatar con iniciales, teléfono formateado y la marca de '
        'WhatsApp si aceptó', (tester) async {
      signInAs('Employee');
      repo.pageResult = Right(page([
        ana,
        const ClientEntity(
            id: 'c2',
            name: 'Bea',
            lastname: 'Ruiz',
            phone: '3109998888',
            whatsappOptIn: true),
      ]));
      putListController();
      await pump(tester, const ClientsScreen());

      final avatar = tester.widget<AppAvatar>(find.descendant(
          of: find.ancestor(
              of: find.text('Ana Pérez'), matching: find.byType(AppCard)),
          matching: find.byType(AppAvatar)));
      expect(avatar.name, 'Ana Pérez');
      expect(find.text('AP'), findsOneWidget);
      expect(find.text('BR'), findsOneWidget);
      expect(find.textContaining('300 123 4567'), findsOneWidget);
      expect(find.byTooltip('Acepta recordatorios por WhatsApp'),
          findsOneWidget);
      expect(find.text('2 clientes'), findsOneWidget);
    });

    testWidgets('buscar: el botón de borrar aparece con texto y vacía la '
        'búsqueda', (tester) async {
      signInAs('Owner');
      final c = putListController();
      await pump(tester, const ClientsScreen());

      expect(find.byTooltip('Borrar búsqueda'), findsNothing);
      await tester.enterText(find.byType(AppSearchField), 'ana');
      await tester.pump();
      expect(c.searchQuery.value, 'ana');
      await tester.tap(find.byTooltip('Borrar búsqueda'));
      await tester.pump();
      expect(c.searchQuery.value, isEmpty);
      expect(c.searchController.text, isEmpty);
      expect(find.byTooltip('Borrar búsqueda'), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    testWidgets('filtros en una AppSheet y el punto en el botón',
        (tester) async {
      signInAs('Owner');
      final c = putListController();
      await pump(tester, const ClientsScreen());

      Badge badge() => tester.widget<Badge>(find.ancestor(
          of: find.byTooltip('Filtros'), matching: find.byType(Badge)));
      expect(badge().isLabelVisible, isFalse);
      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();
      expect(find.byType(AppSheet), findsOneWidget);
      expect(find.text('Filtrar clientes'), findsOneWidget);
      await tester.tap(find.byKey(const Key('filter-without-consent')));
      await tester.pumpAndSettle();
      expect(c.withoutConsent.value, isTrue);
      expect(badge().isLabelVisible, isTrue);
    });

    testWidgets('ficha: cabecera con nombre y teléfono, y foto con AppAvatar',
        (tester) async {
      signInAs('Owner');
      putEditController();
      await pump(tester, const EditClientScreen());

      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('300 123 4567'), findsOneWidget);
      expect(find.byType(AppAvatar), findsOneWidget);
      expect(find.bySemanticsLabel('Agregar foto'), findsOneWidget);
      // Secciones del formulario.
      expect(find.text('Información básica'), findsOneWidget);
      expect(find.text('Recordatorios por WhatsApp'), findsOneWidget);
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
  
    testWidgets('Llamar y WhatsApp con el teléfono guardado (Employee)',
        (tester) async {
      signInAs('Employee');
      opened.clear();
      putEditController();
      await pump(tester, const EditClientScreen());

      await tapText(tester, 'Llamar');
      await tapText(tester, 'WhatsApp');

      expect(opened.map((u) => u.toString()),
          ['tel:3001234567', 'https://wa.me/573001234567']);
    });

    testWidgets('consentimiento: aceptó el…; desmarcar es darse de baja',
        (tester) async {
      signInAs('Owner');
      repo.byIdResult = Right(ana.copyWith(whatsappOptIn: true)
          .withConsentDates(DateTime(2026, 10, 30)));
      putEditController();
      await pump(tester, const EditClientScreen());
      expect(find.text('Aceptó el 30/10/2026.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('client-whatsapp-opt-in')));
      await tester.pump();
      await tapText(tester, 'Guardar cambios');
      expect(repo.updated.single.whatsappOptIn, isFalse);
      await expireSnackbar(tester);
    });

    testWidgets('sin consentimiento: marcar y desmarcar no da de baja',
        (tester) async {
      signInAs('Owner');
      putEditController();
      await pump(tester, const EditClientScreen());
      expect(find.textContaining('Márcala solo si el cliente te dio permiso'),
          findsOneWidget);
      final c = Get.find<EditClientController>();
      c.setWhatsappOptIn(true);
      expect(c.whatsappOptIn.value, isTrue);
      c.setWhatsappOptIn(false);
      expect(c.whatsappOptIn.value, isNull, reason: 'sin tocar, no es baja');
    });

    testWidgets('pedir consentimiento: link y wa.me con el texto prellenado',
        (tester) async {
      signInAs('Employee');
      opened.clear();
      putEditController();
      await pump(tester, const EditClientScreen());
      await tapText(tester, 'Pedir consentimiento por WhatsApp');

      expect(repo.consentRequests, ['c1']);
      final uri = opened.single;
      expect(uri.host, 'wa.me');
      expect(uri.path, '/573001234567');
      expect(
          uri.queryParameters['text'],
          'Hola Ana, Cejas Luna quiere enviarte recordatorios de tus citas '
          'por WhatsApp. Si estás de acuerdo, acepta aquí: '
          'http://api.test/consentimiento/tok-1');
    });

    testWidgets('si ya aceptó: "Ya aceptó" y sin botón', (tester) async {
      signInAs('Owner');
      opened.clear();
      repo.consentResult = const Right(ConsentLink(
          url: 'https://x.co/consentimiento/t', path: '/consentimiento/t',
          alreadyOptedIn: true));
      putEditController();
      await pump(tester, const EditClientScreen());
      await tapText(tester, 'Pedir consentimiento por WhatsApp');
      expect(opened, isEmpty);
      expect(find.byKey(const Key('client-consent-accepted')), findsOneWidget);
      expect(find.text('Pedir consentimiento por WhatsApp'), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('sin conexión: aviso claro', (tester) async {
      signInAs('Owner');
      opened.clear();
      repo.consentResult =
          const Left(NetworkFailure(message: 'Sin conexión a internet'));
      putEditController();
      await pump(tester, const EditClientScreen());
      await tapText(tester, 'Pedir consentimiento por WhatsApp');
      expect(opened, isEmpty);
      expect(find.textContaining('hace falta internet'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('origen del consentimiento: desde el link', (tester) async {
      signInAs('Owner');
      repo.byIdResult = Right(ClientEntity(
        id: 'c1',
        name: 'Ana',
        phone: '3001234567',
        whatsappOptIn: true,
        whatsappOptInAt: DateTime(2026, 10, 30),
        whatsappOptInSource: ConsentSource.link,
      ));
      putEditController();
      await pump(tester, const EditClientScreen());
      expect(find.text('Aceptó desde el link el 30/10/2026.'), findsOneWidget);
      expect(find.text('Pedir consentimiento por WhatsApp'), findsNothing);
    });

    testWidgets('sin teléfono no hay Llamar ni WhatsApp', (tester) async {
      signInAs('Owner');
      repo.byIdResult = const Right(ClientEntity(id: 'c1', name: 'Sin', phone: ''));
      putEditController();
      await pump(tester, const EditClientScreen());

      expect(find.text('Llamar'), findsNothing);
      expect(find.text('WhatsApp'), findsNothing);
    });
  });

  test('número para wa.me: misma regla que el backend', () {
    expect(toWhatsappPhone('300 123 4567'), '573001234567');
    expect(toWhatsappPhone('+1 (555) 123-4567'), '15551234567');
    expect(toWhatsappPhone('573001234567'), '573001234567');
    expect(toWhatsappPhone('12345'), '12345');
    expect(whatsappUri(''), isNull);
    expect(phoneCallUri('+57 300-123'), Uri.parse('tel:+57300123'));
  });
}

extension on ClientEntity {
  /// Copia con la fecha de aceptación (copyWith no la cambia).
  ClientEntity withConsentDates(DateTime acceptedAt) => ClientEntity(
        id: this.id,
        name: name,
        lastname: lastname,
        phone: phone,
        email: email,
        address: address,
        whatsappOptIn: whatsappOptIn,
        whatsappOptInAt: acceptedAt,
      );
}

class _FakeSettings implements SettingsRepository {
  @override
  Future<Either<Failure, BusinessSettings>> getSettings() async =>
      const Right(BusinessSettings(timeZone: 'America/Bogota', name: 'Cejas Luna'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
