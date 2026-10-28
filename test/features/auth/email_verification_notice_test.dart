import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/features/auth/presentation/controllers/email_verification_notice_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/email_verification_notice.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/shared/controller/session_controller.dart';

import '../../core/session/memory_token_store.dart';

/// `GET /auth/employees` devuelve al propio Owner con `is_email_verified`.
class FakeTeamRepository implements EmployeesRepository {
  bool ownerVerified = false;
  int calls = 0;

  @override
  Future<Either<Failure, List<EmployeeEntity>>> getEmployees() async {
    calls++;
    return Right([
      EmployeeEntity(
        id: 'o1',
        name: 'Olga',
        lastname: '',
        email: 'olga@mail.com',
        isActive: true,
        isEmailVerified: ownerVerified,
        isOwner: true,
      ),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeTeamRepository repo;
  late SessionController session;

  setUp(() {
    Get.testMode = true;
    repo = FakeTeamRepository();
  });
  tearDown(Get.reset);

  void signInAs(String role, {String userId = 'o1'}) {
    final store = MemoryTokenStore();
    session = SessionController(SessionService(
      tokenStore: store,
      repository: SessionRepository(store),
    ));
    session.session.value = Session(token: 't', userId: userId, roles: [role]);
    Get.put<SessionController>(session, permanent: true);
  }

  Future<void> pumpMenu(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      theme: ThemeConfig.lightTheme,
      initialRoute: GetRoutes.home,
      getPages: [
        // Como `AppointmentsBinding`: la home registra el aviso.
        GetPage(
          name: GetRoutes.home,
          page: () => const Scaffold(body: EmailVerificationNotice()),
          binding: BindingsBuilder(() => Get.lazyPut(() =>
              EmailVerificationNoticeController(
                  getEmployeesUseCase: GetEmployeesUseCase(repo),
                  session: session))),
        ),
        GetPage(
          name: GetRoutes.verifyEmail,
          page: () => Scaffold(body: Text('verificar ${Get.arguments}')),
        ),
      ],
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Owner sin verificar: aviso que abre la verificación',
      (tester) async {
    signInAs('Owner');
    await pumpMenu(tester);

    expect(find.text('Verifica tu email'), findsOneWidget);
    expect(find.text('Te enviaremos un código a olga@mail.com'), findsOneWidget);

    await tester.tap(find.text('Verifica tu email'));
    await tester.pumpAndSettle();
    expect(find.text('verificar {email: olga@mail.com}'), findsOneWidget);
  });

  testWidgets('al verificar (vuelta a la home) el aviso desaparece',
      (tester) async {
    signInAs('Owner');
    await pumpMenu(tester);
    expect(find.text('Verifica tu email'), findsOneWidget);

    // Verificar entra a la home con `offAllNamed`: la ruta crea un
    // controller nuevo, que vuelve a consultar.
    repo.ownerVerified = true;
    Get.offAllNamed(GetRoutes.home);
    await tester.pumpAndSettle();

    expect(repo.calls, 2);

    expect(find.text('Verifica tu email'), findsNothing);
  });

  testWidgets('el Employee no ve el aviso ni se consulta nada',
      (tester) async {
    signInAs('Employee', userId: 'e1');
    await pumpMenu(tester);

    expect(find.text('Verifica tu email'), findsNothing);
    expect(repo.calls, 0);
  });
}
