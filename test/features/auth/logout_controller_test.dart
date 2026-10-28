import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
import 'package:login_signup/features/auth/domain/usecases/logout_usecase.dart';
import 'package:login_signup/features/auth/presentation/controllers/logout_controller.dart';
import 'package:login_signup/shared/controller/session_controller.dart';

import '../../core/session/jwt_helper.dart';
import '../../core/session/memory_token_store.dart';

class _Repo implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLogout extends LogoutUseCase {
  int calls = 0;
  _FakeLogout() : super(_Repo());
  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    calls++;
    return const Right(unit);
  }
}

void main() {
  late MemoryTokenStore store;
  late _FakeLogout useCase;
  late List<String> steps;
  late LogoutController controller;

  setUp(() {
    Get.testMode = true;
    store = MemoryTokenStore()
      ..token = fakeJwt({
        'id': 'u1',
        'name': 'Ana',
        'email': 'ana@test.co',
        'roles': ['Owner'],
        'exp': epochSeconds(DateTime.now().add(const Duration(hours: 1))),
      });
    // Permanente, como en SessionBinding.
    Get.put(
      SessionController(SessionService(
        tokenStore: store,
        repository: SessionRepository(store),
      )),
      permanent: true,
    );
    useCase = _FakeLogout();
    steps = [];
    controller = LogoutController(
      logoutUseCase: useCase,
      afterNavigation: () async => steps.add('navegó'),
      resetScope: () async => steps.add('reset'),
    );
  });
  tearDown(Get.reset);

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: GetRoutes.home,
      getPages: [
        GetPage(
            name: GetRoutes.home,
            page: () => const Scaffold(body: Text('home'))),
        GetPage(
            name: GetRoutes.login,
            page: () => const Scaffold(body: Text('login'))),
      ],
    ));
    await Get.find<SessionController>().restore();
  }

  testWidgets('borra la sesión, va a login y después limpia los controllers',
      (tester) async {
    await pumpApp(tester);
    expect(Get.find<SessionController>().isLoggedIn, isTrue);

    await controller.logout();
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(store.token, isNull);
    expect(Get.find<SessionController>().isLoggedIn, isFalse);
    expect(useCase.calls, 1);
    expect(steps, ['navegó', 'reset']);
    expect(controller.isLoading.value, isFalse);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('se puede cerrar sesión otra vez sin reiniciar la app',
      (tester) async {
    // Antes, el método esperaba el Future de offAllNamed (que no termina
    // mientras la ruta de login existe) y el segundo logout no hacía nada.
    await pumpApp(tester);
    await controller.logout();
    await tester.pumpAndSettle();
    Get.offAllNamed(GetRoutes.home);
    await tester.pumpAndSettle();

    await controller.endSession(expired: true);
    await tester.pumpAndSettle();

    expect(useCase.calls, 2);
    expect(steps, ['navegó', 'reset', 'navegó', 'reset']);
    expect(find.text('Sesión expirada'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
