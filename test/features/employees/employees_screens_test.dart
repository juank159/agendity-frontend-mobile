import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/employee_input.dart';
import 'package:login_signup/features/employees/domain/entities/employee_restoration.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/features/employees/domain/usecases/create_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/delete_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_deleted_employees_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/request_employee_verification_code_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/restore_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/toggle_employee_status_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/update_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/verify_employee_email_usecase.dart';
import 'package:login_signup/features/employees/presentation/controllers/edit_employee_controller.dart';
import 'package:login_signup/features/employees/presentation/controllers/employee_form_controller.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/employees/presentation/controllers/new_employee_controller.dart';
import 'package:login_signup/features/employees/presentation/controllers/verify_employee_email_controller.dart';
import 'package:login_signup/features/employees/presentation/screens/create_employee_screen.dart';
import 'package:login_signup/features/employees/presentation/screens/edit_employee_screen.dart';
import 'package:login_signup/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:login_signup/features/employees/presentation/screens/employees_list_screen.dart';
import 'package:login_signup/features/employees/presentation/screens/verify_employee_email_screen.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';

/// Repositorio falso con estado: pantallas, controllers y use cases son los
/// reales.
class FakeEmployeesRepository implements EmployeesRepository {
  List<EmployeeEntity> team = [];
  List<EmployeeEntity> deleted = [];

  /// Si no es `null`, `getEmployees` falla con él.
  Failure? listFailure;

  /// Si no es `null`, `setEmployeeActive` falla con él.
  Failure? statusFailure;

  final created = <EmployeeInput>[];
  final statusCalls = <(String, bool)>[];
  final deletions = <(String, String?)>[];
  final restored = <String>[];
  final codeRequests = <String>[];
  final verifications = <(String, String)>[];

  @override
  Future<Either<Failure, List<EmployeeEntity>>> getEmployees() async =>
      listFailure != null ? Left(listFailure!) : Right(List.of(team));

  @override
  Future<Either<Failure, List<EmployeeEntity>>> getDeletedEmployees() async =>
      Right(List.of(deleted));

  @override
  Future<Either<Failure, EmployeeEntity>> getEmployeeById(String id) async {
    final found = team.where((e) => e.id == id);
    return found.isEmpty ? const Left(NotFoundFailure()) : Right(found.first);
  }

  @override
  Future<Either<Failure, EmployeeEntity>> createEmployee(
      EmployeeInput input) async {
    created.add(input);
    final employee = EmployeeEntity(
      id: 'new-${created.length}',
      name: input.name,
      lastname: input.lastname,
      email: input.email,
      phone: input.phone,
      isActive: false,
      isEmailVerified: false,
    );
    team.add(employee);
    return Right(employee);
  }

  @override
  Future<Either<Failure, EmployeeEntity>> updateEmployee(
      String id, EmployeeInput input) async {
    final index = team.indexWhere((e) => e.id == id);
    team[index] = team[index].copyWith(name: input.name);
    return Right(team[index]);
  }

  @override
  Future<Either<Failure, Unit>> setEmployeeActive(
      String id, bool isActive) async {
    statusCalls.add((id, isActive));
    if (statusFailure != null) return Left(statusFailure!);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteEmployee(String id,
      {String? reason}) async {
    deletions.add((id, reason));
    final employee = team.firstWhere((e) => e.id == id);
    team.remove(employee);
    deleted.add(employee.markDeleted(at: DateTime(2026, 10, 27), reason: reason));
    return const Right(unit);
  }

  @override
  Future<Either<Failure, EmployeeRestoration>> restoreEmployee(
      String id) async {
    restored.add(id);
    final employee = deleted.firstWhere((e) => e.id == id);
    deleted.remove(employee);
    final back = employee.markRestored(isActive: employee.isEmailVerified);
    team.add(back);
    return Right(
        EmployeeRestoration(employeeId: id, isActive: back.isActive));
  }

  @override
  Future<Either<Failure, Unit>> requestVerificationCode(String email) async {
    codeRequests.add(email);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> verifyEmployeeEmail({
    required String employeeId,
    required String code,
  }) async {
    verifications.add((employeeId, code));
    if (code != '123456') {
      return const Left(InvalidEmployeeVerificationCodeFailure());
    }
    final index = team.indexWhere((e) => e.id == employeeId);
    team[index] =
        team[index].copyWith(isActive: true, isEmailVerified: true);
    return const Right(unit);
  }
}

class FakeServicesRepository implements ServicesRepository {
  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices() async =>
      const Right([corte]);

  @override
  Future<Either<Failure, ServiceEntity>> createService(
          ServiceEntity service) async =>
      Right(service);

  @override
  Future<Either<Failure, ServiceEntity>> updateService(
          ServiceEntity service) async =>
      Right(service);

  @override
  Future<Either<Failure, Unit>> deleteService(String id) async =>
      const Right(unit);
}

const corte = ServiceEntity(
    id: 's1', name: 'Corte', price: 20000, duration: 30, categoryId: 'c1');

const owner = EmployeeEntity(
  id: 'o1',
  name: 'Olga',
  lastname: 'Dueña',
  email: 'olga@mail.com',
  isActive: true,
  isEmailVerified: true,
  isOwner: true,
);
const ana = EmployeeEntity(
  id: 'e1',
  name: 'Ana',
  lastname: 'Pérez',
  email: 'ana@mail.com',
  phone: '3001234567',
  isActive: true,
  isEmailVerified: true,
  serviceAssignments: {
    's1': ServiceAssignment(
        serviceId: 's1', serviceName: 'Corte', commissionPercentage: 10),
  },
);
const luis = EmployeeEntity(
  id: 'e2',
  name: 'Luis',
  lastname: 'Gómez',
  email: 'luis@mail.com',
  isActive: false,
  isEmailVerified: false,
);
const marta = EmployeeEntity(
  id: 'e3',
  name: 'Marta',
  lastname: 'Ruiz',
  email: 'marta@mail.com',
  isActive: false,
  isEmailVerified: true,
);

void main() {
  late FakeEmployeesRepository repo;
  late FakeServicesRepository services;

  setUpAll(() => initializeDateFormatting('es'));
  setUp(() {
    Get.testMode = true;
    repo = FakeEmployeesRepository()..team = [owner, ana, luis, marta];
    services = FakeServicesRepository();
  });
  tearDown(Get.reset);

  /// Las rutas de la feature con bindings como los de la app, pero sobre los
  /// repositorios falsos.
  List<GetPage> pages() => [
        GetPage(
          name: GetRoutes.employees,
          page: () => const EmployeesListScreen(),
          binding: BindingsBuilder(() => Get.lazyPut(() => EmployeesController(
                getEmployeesUseCase: GetEmployeesUseCase(repo),
                getDeletedEmployeesUseCase: GetDeletedEmployeesUseCase(repo),
                toggleEmployeeStatusUseCase: ToggleEmployeeStatusUseCase(repo),
                deleteEmployeeUseCase: DeleteEmployeeUseCase(repo),
                restoreEmployeeUseCase: RestoreEmployeeUseCase(repo),
              ))),
        ),
        GetPage(
          name: GetRoutes.addEmployee,
          page: () => const CreateEmployeeScreen(),
          binding: BindingsBuilder(() => Get.lazyPut(() => NewEmployeeController(
                createEmployeeUseCase: CreateEmployeeUseCase(repo),
                getServicesUseCase: GetServicesUseCase(services),
              ))),
        ),
        GetPage(
          name: GetRoutes.employeeEdit,
          page: () => const EditEmployeeScreen(),
          binding: BindingsBuilder(() => Get.lazyPut(() => EditEmployeeController(
                getEmployeeByIdUseCase: GetEmployeeByIdUseCase(repo),
                updateEmployeeUseCase: UpdateEmployeeUseCase(repo),
                getServicesUseCase: GetServicesUseCase(services),
              ))),
        ),
        GetPage(
          name: GetRoutes.employeeDetails,
          page: () => const EmployeeDetailsScreen(),
        ),
        GetPage(
          name: GetRoutes.verifyEmployeeEmail,
          page: () => const VerifyEmployeeEmailScreen(),
          binding: BindingsBuilder(
              () => Get.lazyPut(() => VerifyEmployeeEmailController(
                    requestVerificationCodeUseCase:
                        RequestEmployeeVerificationCodeUseCase(repo),
                    verifyEmployeeEmailUseCase:
                        VerifyEmployeeEmailUseCase(repo),
                  ))),
        ),
      ];

  Future<void> pumpList(WidgetTester tester) async {
    // Pantalla alta: el formulario y la lista se construyen enteros.
    tester.view.physicalSize = const Size(1000, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(
      theme: ThemeConfig.lightTheme,
      initialRoute: GetRoutes.employees,
      getPages: pages(),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  /// La pantalla de verificación nunca "se asienta" (cursor del código y
  /// cuenta atrás): se avanza un tiempo fijo.
  Future<void> pumpFor(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> openOptions(WidgetTester tester, EmployeeEntity e) async {
    await tester.tap(find.byTooltip('Opciones de ${e.fullName}'));
    await tester.pumpAndSettle();
  }

  /// Deja que el snackbar se cierre (si no, el test termina con timers).
  Future<void> expireSnackbar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  Finder chip(EmployeeEntity e, String label) => find.descendant(
      of: find.ancestor(
          of: find.text(e.fullName), matching: find.byType(Card)),
      matching: find.text(label));

  group('Lista', () {
    testWidgets('muestra cada estado con su texto y al Propietario',
        (tester) async {
      await pumpList(tester);

      expect(chip(ana, 'Activo'), findsOneWidget);
      expect(chip(luis, 'Pendiente de verificación'), findsOneWidget);
      expect(chip(marta, 'Inactivo'), findsOneWidget);
      expect(chip(owner, 'Propietario'), findsOneWidget);
      expect(find.text('Equipo (4)'), findsOneWidget);
    });

    testWidgets('un error se muestra con reintento, no como lista vacía',
        (tester) async {
      repo.listFailure =
          const NetworkFailure(message: 'Sin conexión a internet');
      await pumpList(tester);

      expect(find.text('Sin conexión a internet'), findsOneWidget);
      expect(find.text('Aún no tienes profesionales'), findsNothing);

      repo.listFailure = null;
      await tapText(tester, 'Reintentar');
      expect(find.text('Ana Pérez'), findsOneWidget);
    });

    testWidgets('sin profesionales: estado vacío con "Agregar profesional"',
        (tester) async {
      repo.team = [];
      await pumpList(tester);

      expect(find.text('Aún no tienes profesionales'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Agregar profesional'),
          findsOneWidget);
    });

    testWidgets('la búsqueda filtra y avisa si no hay resultados',
        (tester) async {
      await pumpList(tester);

      await tester.enterText(find.byType(TextField), 'marta');
      await tester.pumpAndSettle();
      expect(find.text('Marta Ruiz'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Sin resultados para "zzz"'), findsOneWidget);
    });
  });

  group('Alta', () {
    testWidgets('el profesional nace pendiente de verificación',
        (tester) async {
      await pumpList(tester);
      await tester.tap(find.byTooltip('Agregar profesional'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, 'Nombre *'), 'Sara');
      await tester.enterText(
          find.widgetWithText(TextField, 'Apellido *'), 'Mora');
      await tester.enterText(
          find.widgetWithText(TextField, 'Email *'), 'sara@mail.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Teléfono *'), '3109876543');
      await tester.enterText(
          find.widgetWithText(TextField, 'Contraseña *'), 'Clave@2026');
      await tester.tap(find.text('Corte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear profesional'));
      await pumpFor(tester);

      // Se creó con el horario por defecto y se abrió la verificación.
      expect(repo.created.single.schedule.keys,
          ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']);
      expect(repo.created.single.services.keys, ['s1']);
      expect(repo.codeRequests, ['sara@mail.com']);
      expect(find.text('Verifica el email de Sara Mora'), findsOneWidget);

      // Sale sin verificar: vuelve a la lista, que lo muestra pendiente.
      await tester.tap(find.byTooltip('Salir sin verificar'));
      await pumpFor(tester);
      await tapText(tester, 'Salir');

      expect(find.text('Sara Mora'), findsOneWidget);
      expect(chip(repo.team.last, 'Pendiente de verificación'),
          findsOneWidget);
      expect(find.textContaining('queda pendiente de verificación'),
          findsOneWidget);
      expect(Get.isRegistered<VerifyEmployeeEmailController>(), isFalse);
      await expireSnackbar(tester);
    });

    testWidgets('sin servicios no llama al backend', (tester) async {
      await pumpList(tester);
      await tester.tap(find.byTooltip('Agregar profesional'));
      await tester.pumpAndSettle();

      await tapText(tester, 'Crear profesional');

      expect(repo.created, isEmpty);
      expect(find.text(EmployeeFormController.servicesRequired),
          findsOneWidget);
      await expireSnackbar(tester);
    });
  });

  group('Activar', () {
    testWidgets('sin el email verificado: muestra el motivo', (tester) async {
      repo.statusFailure = const EmployeeEmailNotVerifiedFailure();
      await pumpList(tester);

      await openOptions(tester, luis);
      expect(find.text('Requiere el email verificado'), findsOneWidget);
      await tapText(tester, 'Activar');
      await tapText(tester, 'Activar'); // confirmación

      expect(repo.statusCalls, [('e2', true)]);
      expect(find.text('Falta verificar el email'), findsOneWidget);
      expect(find.text(EmployeeEmailNotVerifiedFailure.defaultMessage),
          findsOneWidget);
      await tapText(tester, 'Ahora no');
      expect(chip(luis, 'Pendiente de verificación'), findsOneWidget);
    });

    testWidgets('verificar el email desde el motivo lo deja activo',
        (tester) async {
      repo.statusFailure = const EmployeeEmailNotVerifiedFailure();
      await pumpList(tester);

      await openOptions(tester, luis);
      await tapText(tester, 'Activar');
      await tapText(tester, 'Activar');
      await tester.tap(find.widgetWithText(FilledButton, 'Verificar email'));
      await pumpFor(tester);

      expect(find.text('Verifica el email de Luis Gómez'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '000000');
      await pumpFor(tester);
      expect(find.text(InvalidEmployeeVerificationCodeFailure.defaultMessage),
          findsOneWidget);

      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.pumpAndSettle();

      expect(repo.verifications.last, ('e2', '123456'));
      expect(chip(luis, 'Activo'), findsOneWidget);
      expect(find.text('Email verificado'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('desactivar a un activo', (tester) async {
      await pumpList(tester);

      await openOptions(tester, ana);
      await tapText(tester, 'Desactivar');
      await tapText(tester, 'Desactivar');

      expect(repo.statusCalls, [('e1', false)]);
      expect(chip(ana, 'Inactivo'), findsOneWidget);
      await expireSnackbar(tester);
    });
  });

  group('Borrar y restaurar', () {
    testWidgets('borrar con motivo y restaurarlo desde "Eliminados"',
        (tester) async {
      await pumpList(tester);

      await openOptions(tester, ana);
      await tapText(tester, 'Eliminar');
      await tester.enterText(
          find.widgetWithText(TextField, 'Motivo (opcional)'), 'Renuncia');
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(repo.deletions, [('e1', 'Renuncia')]);
      expect(find.text('Ana Pérez'), findsNothing);
      await expireSnackbar(tester);

      await tapText(tester, 'Eliminados');
      expect(chip(ana, 'Eliminado'), findsOneWidget);
      await openOptions(tester, ana);
      expect(find.text('Motivo: Renuncia'), findsOneWidget);
      expect(find.text('Editar'), findsNothing);
      await tapText(tester, 'Restaurar');
      await tapText(tester, 'Restaurar'); // confirmación

      expect(repo.restored, ['e1']);
      expect(find.text('Ana Pérez'), findsNothing);
      expect(find.text('No hay profesionales eliminados'), findsOneWidget);
      await expireSnackbar(tester);

      await tapText(tester, 'Equipo (4)');
      expect(chip(ana, 'Activo'), findsOneWidget);
    });

    testWidgets('cancelar la baja no llama al backend', (tester) async {
      await pumpList(tester);

      await openOptions(tester, marta);
      await tapText(tester, 'Eliminar');
      await tapText(tester, 'Cancelar');

      expect(repo.deletions, isEmpty);
      expect(find.text('Marta Ruiz'), findsOneWidget);
    });
  });

  group('Owner', () {
    testWidgets('no se puede editar, desactivar ni borrar', (tester) async {
      await pumpList(tester);

      await openOptions(tester, owner);
      expect(find.text('Ver detalles'), findsOneWidget);
      expect(find.text('Editar'), findsNothing);
      expect(find.text('Desactivar'), findsNothing);
      expect(find.text('Eliminar'), findsNothing);
      expect(find.textContaining('Eres el propietario'), findsOneWidget);

      final controller = Get.find<EmployeesController>();
      expect(await controller.delete(owner), isFalse);
      expect(await controller.setActive(owner, false), isFalse);
      expect(repo.deletions, isEmpty);
      expect(repo.statusCalls, isEmpty);
    });
  });

  group('Edición y detalle', () {
    testWidgets('edita por la ruta con nombre y el email es de solo lectura',
        (tester) async {
      await pumpList(tester);

      await openOptions(tester, ana);
      await tapText(tester, 'Editar');

      expect(find.text('Editar profesional'), findsOneWidget);
      final email = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Email *'));
      expect(email.readOnly, isTrue);

      await tester.enterText(
          find.widgetWithText(TextField, 'Nombre *'), 'Anita');
      await tapText(tester, 'Guardar cambios');

      expect(find.text('Anita Pérez'), findsOneWidget);
      expect(Get.isRegistered<EditEmployeeController>(), isFalse);
      await expireSnackbar(tester);
    });

    testWidgets('el detalle muestra estado y motivo del pendiente',
        (tester) async {
      await pumpList(tester);

      await tester.tap(find.text('Luis Gómez'));
      await tester.pumpAndSettle();

      expect(find.text('Detalle del profesional'), findsOneWidget);
      expect(find.text('Pendiente de verificación'), findsOneWidget);
      expect(find.textContaining('Debe verificar su email'), findsOneWidget);
    });
  });
}
