import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/middlewares/auth_middleware.dart';
import 'package:login_signup/core/routes/middlewares/role_middleware.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';

import '../session/jwt_helper.dart';
import '../session/memory_token_store.dart';

void main() {
  final now = DateTime.utc(2026, 10, 23, 12);
  late MemoryTokenStore store;
  late SessionController session;

  String token(List<String> roles,
          {Duration expiresIn = const Duration(hours: 1)}) =>
      fakeJwt({
        'id': 'u1',
        'roles': roles,
        'exp': epochSeconds(now.add(expiresIn)),
      });

  setUp(() {
    Get.testMode = true;
    store = MemoryTokenStore();
    session = SessionController(
      SessionService(
        tokenStore: store,
        repository: SessionRepository(store, clock: () => now),
      ),
      clock: () => now,
    );
  });

  group('AuthMiddleware', () {
    test('sin SessionController registrado redirige al login', () {
      final middleware = AuthMiddleware(lookup: () => null);
      expect(middleware.redirect(GetRoutes.home)?.name, GetRoutes.login);
    });

    test('sin sesión redirige al login', () {
      final middleware = AuthMiddleware(lookup: () => session);
      expect(middleware.redirect(GetRoutes.home)?.name, GetRoutes.login);
    });

    test('con sesión vigente deja pasar', () async {
      await session.start(token(['Employee']));
      final middleware = AuthMiddleware(lookup: () => session);
      expect(middleware.redirect(GetRoutes.home), isNull);
    });

    test('con sesión vencida redirige al login', () async {
      session.session.value = SessionRepository.decode(
          token(['Owner'], expiresIn: const Duration(minutes: -1)));
      final middleware = AuthMiddleware(lookup: () => session);
      expect(middleware.redirect(GetRoutes.home)?.name, GetRoutes.login);
    });
  });

  group('RoleMiddleware', () {
    test('Owner pasa', () async {
      await session.start(token(['Owner', 'Employee']));
      expect(RoleMiddleware(lookup: () => session).redirect(GetRoutes.employees),
          isNull);
    });

    test('Employee vuelve a la home', () async {
      await session.start(token(['Employee']));
      expect(
          RoleMiddleware(lookup: () => session)
              .redirect(GetRoutes.employees)
              ?.name,
          GetRoutes.home);
    });

    test('sin sesión va al login', () {
      expect(
          RoleMiddleware(lookup: () => session)
              .redirect(GetRoutes.employees)
              ?.name,
          GetRoutes.login);
    });

    test('se ejecuta después de AuthMiddleware', () {
      final chain = RoleMiddleware.ownerOnly();
      expect(chain.first, isA<AuthMiddleware>());
      expect(chain.last, isA<RoleMiddleware>());
      expect(chain.last.priority!, greaterThan(chain.first.priority!));
    });
  });

  group('rutas', () {
    const ownerOnly = [
      GetRoutes.employees,
      GetRoutes.addEmployee,
      GetRoutes.statistics,
      GetRoutes.configWhatsapp,
      GetRoutes.subscriptionPlans,
    ];
    const public = [
      GetRoutes.splas,
      GetRoutes.login,
      GetRoutes.register,
      GetRoutes.verifyEmail,
      GetRoutes.forgotPassword,
      GetRoutes.resetPassword,
    ];

    GetPage page(String name) =>
        GetRoutes.routes.firstWhere((p) => p.name == name);

    test('las rutas solo de Owner llevan RoleMiddleware', () {
      for (final name in ownerOnly) {
        expect(page(name).middlewares?.whereType<RoleMiddleware>(), isNotEmpty,
            reason: name);
      }
    });

    test('la home y las de Employee exigen sesión sin exigir Owner', () {
      for (final name in [
        GetRoutes.home,
        GetRoutes.employeeStats,
        GetRoutes.clients
      ]) {
        final middlewares = page(name).middlewares ?? const [];
        expect(middlewares.whereType<AuthMiddleware>(), isNotEmpty,
            reason: name);
        expect(middlewares.whereType<RoleMiddleware>(), isEmpty, reason: name);
      }
    });

    test('las rutas de autenticación son públicas', () {
      for (final name in public) {
        expect(page(name).middlewares ?? const [], isEmpty, reason: name);
      }
    });
  });
}
