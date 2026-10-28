import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/features/auth/domain/entities/register_owner_input.dart';
import 'package:login_signup/features/auth/domain/entities/user_entity.dart';
import 'package:login_signup/features/auth/domain/failures/auth_failures.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
import 'package:login_signup/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/login_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/register_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/request_verification_code_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/verify_email_usecase.dart';
import 'package:login_signup/features/auth/presentation/controllers/email_verification_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/google_auth_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/login_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/register_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:login_signup/features/auth/presentation/screen/email_verification_view.dart';
import 'package:login_signup/features/auth/presentation/screen/forgot_password_view.dart';
import 'package:login_signup/features/auth/presentation/screen/login_view.dart';
import 'package:login_signup/features/auth/presentation/screen/register_view.dart';
import 'package:login_signup/features/auth/presentation/screen/reset_password_view.dart';
import 'package:login_signup/shared/controller/session_controller.dart';

import '../../core/session/jwt_helper.dart';
import '../../core/session/memory_token_store.dart';

/// Repositorio falso: las pantallas, controllers y use cases son los reales.
/// Como el de la app, inicia la sesión (`SessionService.start`) antes de
/// devolver el usuario en login, registro y Google.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.session);

  final SessionService session;

  Failure? loginFailure;
  Failure? registerFailure;
  Failure? googleFailure;

  final logins = <(String, String)>[];
  final registered = <RegisterOwnerInput>[];
  final codeRequests = <String>[];
  final verifications = <(String, String)>[];
  final resetRequests = <String>[];
  final resets = <(String, String, String)>[];

  static const validCode = '123456';

  static const owner = UserEntity(
      id: 'o1', name: 'Olga', lastname: 'Dueña', email: 'olga@mail.com');

  Future<UserEntity> _start(UserEntity user) async {
    await session.start(fakeJwt({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'roles': ['Owner'],
      'exp': epochSeconds(DateTime.now().add(const Duration(days: 1))),
    }));
    return user;
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    logins.add((email, password));
    if (loginFailure != null) return Left(loginFailure!);
    return Right(await _start(owner));
  }

  @override
  Future<Either<Failure, UserEntity>> registerOwner(
      RegisterOwnerInput input) async {
    registered.add(input);
    if (registerFailure != null) return Left(registerFailure!);
    return Right(await _start(UserEntity(
        id: 'o2',
        name: input.name,
        lastname: input.lastname,
        email: input.email)));
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    if (googleFailure != null) return Left(googleFailure!);
    return Right(await _start(owner));
  }

  @override
  Future<Either<Failure, Unit>> requestVerificationCode(String email) async {
    codeRequests.add(email);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> verifyEmail({
    required String email,
    required String code,
  }) async {
    verifications.add((email, code));
    return code == validCode
        ? const Right(unit)
        : const Left(InvalidVerificationCodeFailure(
            message: 'El código es incorrecto o ya venció'));
  }

  @override
  Future<Either<Failure, Unit>> requestPasswordReset(String email) async {
    resetRequests.add(email);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    resets.add((email, code, newPassword));
    return code == validCode
        ? const Right(unit)
        : const Left(InvalidVerificationCodeFailure(
            message: 'El código de recuperación no es válido'));
  }

  @override
  Future<Either<Failure, Unit>> logout() async => const Right(unit);
}

void main() {
  late MemoryTokenStore store;
  late SessionController session;
  late FakeAuthRepository repo;

  setUp(() {
    Get.testMode = true;
    store = MemoryTokenStore();
    final service =
        SessionService(tokenStore: store, repository: SessionRepository(store));
    session = SessionController(service);
    Get.put<SessionController>(session, permanent: true);
    repo = FakeAuthRepository(service);
  });
  tearDown(Get.reset);

  /// Rutas de auth con bindings como los de la app sobre el repositorio falso.
  List<GetPage> pages() => [
        GetPage(
          name: GetRoutes.home,
          page: () => const Scaffold(body: Text('HOME')),
        ),
        GetPage(
          name: GetRoutes.login,
          page: () => const LoginView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(
                () => LoginController(loginUseCase: LoginUseCase(repo)));
            Get.lazyPut(() => GoogleAuthController(
                googleSignInUseCase: GoogleSignInUseCase(repo)));
          }),
        ),
        GetPage(
          name: GetRoutes.register,
          page: () => const RegisterView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() =>
                RegisterController(registerUseCase: RegisterUseCase(repo)));
            Get.lazyPut(() => GoogleAuthController(
                googleSignInUseCase: GoogleSignInUseCase(repo)));
          }),
        ),
        GetPage(
          name: GetRoutes.verifyEmail,
          page: () => const EmailVerificationView(),
          binding: BindingsBuilder(
              () => Get.lazyPut(() => EmailVerificationController(
                    requestCodeUseCase: RequestVerificationCodeUseCase(repo),
                    verifyEmailUseCase: VerifyEmailUseCase(repo),
                  ))),
        ),
        GetPage(
          name: GetRoutes.forgotPassword,
          page: () => const ForgotPasswordView(),
          binding: BindingsBuilder(() => Get.lazyPut(() =>
              ForgotPasswordController(
                  requestPasswordResetUseCase:
                      RequestPasswordResetUseCase(repo)))),
        ),
        GetPage(
          name: GetRoutes.resetPassword,
          page: () => const ResetPasswordView(),
          binding: BindingsBuilder(
              () => Get.lazyPut(() => ResetPasswordController(
                    resetPasswordUseCase: ResetPasswordUseCase(repo),
                    requestPasswordResetUseCase:
                        RequestPasswordResetUseCase(repo),
                  ))),
        ),
      ];

  Future<void> pumpApp(WidgetTester tester, String initialRoute) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(
      theme: ThemeConfig.lightTheme,
      initialRoute: initialRoute,
      getPages: pages(),
    ));
    await tester.pumpAndSettle();
  }

  Finder field(String label) =>
      find.widgetWithText(TextField, label).first;

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  /// Las pantallas con código nunca "se asientan" (cursor y cuenta atrás).
  Future<void> pumpFor(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Deja que el snackbar se cierre (si no, el test termina con timers).
  Future<void> expireSnackbar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  /// Igual en las pantallas con código, que no se asientan.
  Future<void> expireSnackbarOnCodeScreen(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await pumpFor(tester);
  }

  /// Toca y avanza un tiempo fijo (destino o pantalla con código).
  Future<void> tapAndPump(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await pumpFor(tester);
  }

  Future<void> fillLogin(WidgetTester tester) async {
    await tester.enterText(field('Correo electrónico'), 'olga@mail.com');
    await tester.enterText(field('Contraseña'), 'Secreta1!');
  }

  group('Login', () {
    testWidgets('correcto: inicia la sesión y entra a la home',
        (tester) async {
      await pumpApp(tester, GetRoutes.login);
      await fillLogin(tester);
      await tapText(tester, 'Iniciar sesión');

      expect(repo.logins, [('olga@mail.com', 'Secreta1!')]);
      expect(find.text('HOME'), findsOneWidget);
      expect(session.isLoggedIn, isTrue);
      expect(session.isOwner, isTrue);
      expect(find.text('Hola Olga'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('valida el formulario sin llamar al backend', (tester) async {
      await pumpApp(tester, GetRoutes.login);
      await tapText(tester, 'Iniciar sesión');

      expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
      expect(repo.logins, isEmpty);
    });

    testWidgets('credenciales inválidas: marca el campo y no entra',
        (tester) async {
      repo.loginFailure = const InvalidCredentialsFailure();
      await pumpApp(tester, GetRoutes.login);
      await fillLogin(tester);
      await tapText(tester, 'Iniciar sesión');

      // En el campo de contraseña y en el aviso.
      expect(find.text('Correo o contraseña incorrectos'), findsNWidgets(2));
      expect(find.text('HOME'), findsNothing);
      expect(session.isLoggedIn, isFalse);
      await expireSnackbar(tester);
    });

    testWidgets('cuenta inactiva: diálogo con el motivo del backend',
        (tester) async {
      repo.loginFailure = const AccountInactiveFailure(
          message: 'Tu cuenta está desactivada. Habla con el dueño.');
      await pumpApp(tester, GetRoutes.login);
      await fillLogin(tester);
      await tapText(tester, 'Iniciar sesión');

      expect(find.text('Tu cuenta no tiene acceso'), findsOneWidget);
      expect(find.text('Tu cuenta está desactivada. Habla con el dueño.'),
          findsOneWidget);
      await tapText(tester, 'Entendido');
      expect(find.text('HOME'), findsNothing);
    });

    testWidgets('demasiados intentos: pide esperar un minuto',
        (tester) async {
      repo.loginFailure = const TooManyRequestsFailure();
      await pumpApp(tester, GetRoutes.login);
      await fillLogin(tester);
      await tapText(tester, 'Iniciar sesión');

      expect(find.textContaining('Espera un minuto'), findsOneWidget);
      await expireSnackbar(tester);
    });
  });

  group('Google', () {
    testWidgets('cancelar el selector no muestra ningún error',
        (tester) async {
      repo.googleFailure = const GoogleSignInCancelledFailure();
      await pumpApp(tester, GetRoutes.login);
      await tapText(tester, 'Continuar con Google');

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('HOME'), findsNothing);
      expect(find.text('Continuar con Google'), findsOneWidget);
    });

    testWidgets('rechazado por el backend: avisa', (tester) async {
      repo.googleFailure = const GoogleSignInRejectedFailure();
      await pumpApp(tester, GetRoutes.login);
      await tapText(tester, 'Continuar con Google');

      expect(find.text(GoogleSignInRejectedFailure.defaultMessage),
          findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('correcto: entra a la home', (tester) async {
      await pumpApp(tester, GetRoutes.login);
      await tapText(tester, 'Continuar con Google');

      expect(find.text('HOME'), findsOneWidget);
      expect(session.isLoggedIn, isTrue);
    });
  });

  group('Registro', () {
    Future<void> fillRegister(WidgetTester tester) async {
      await tester.enterText(field('Nombre'), 'Olga');
      await tester.enterText(field('Apellidos'), 'Dueña');
      await tester.enterText(field('Teléfono'), '3001234567');
      await tester.enterText(field('Correo electrónico'), 'olga@mail.com');
      await tester.enterText(field('Contraseña'), 'Secreta1!');
      await tester.pump();
    }

    testWidgets('email repetido: marca el campo del email', (tester) async {
      repo.registerFailure =
          const DuplicateEmailFailure(email: 'olga@mail.com');
      await pumpApp(tester, GetRoutes.register);
      await fillRegister(tester);
      await tapText(tester, 'Crear cuenta');

      expect(repo.registered, hasLength(1));
      expect(find.text('Este correo ya está registrado'), findsOneWidget);
      expect(find.text('Este teléfono ya está registrado'), findsNothing);
      expect(Get.currentRoute, GetRoutes.register);
      await expireSnackbar(tester);
    });

    testWidgets('teléfono repetido: marca el campo del teléfono',
        (tester) async {
      repo.registerFailure =
          const DuplicatePhoneFailure(phone: '3001234567');
      await pumpApp(tester, GetRoutes.register);
      await fillRegister(tester);
      await tapText(tester, 'Crear cuenta');

      expect(find.text('Este teléfono ya está registrado'), findsOneWidget);
      expect(find.text('Este correo ya está registrado'), findsNothing);
      await expireSnackbar(tester);
    });

    testWidgets('contraseña débil: muestra los requisitos y no envía',
        (tester) async {
      await pumpApp(tester, GetRoutes.register);
      await fillRegister(tester);
      await tester.enterText(field('Contraseña'), 'abc');
      await tapText(tester, 'Crear cuenta');

      expect(find.text('Requisitos de la contraseña'), findsOneWidget);
      expect(repo.registered, isEmpty);
      await expireSnackbar(tester);
    });

    testWidgets('correcto: pasa a verificar el email y pide el código',
        (tester) async {
      await pumpApp(tester, GetRoutes.register);
      await fillRegister(tester);
      await tapAndPump(tester, 'Crear cuenta');

      expect(Get.currentRoute, GetRoutes.verifyEmail);
      expect(find.text('olga@mail.com'), findsOneWidget);
      expect(repo.codeRequests, ['olga@mail.com']);
      expect(session.isLoggedIn, isFalse,
          reason: 'la sesión de la UI se carga al entrar a la home');
      expect(store.token, isNotNull);
      await expireSnackbarOnCodeScreen(tester);
    });
  });

  group('Verificación del email', () {
    Future<void> openVerification(WidgetTester tester) async {
      await pumpApp(tester, GetRoutes.login);
      Get.offAllNamed(GetRoutes.verifyEmail,
          arguments: {'email': 'olga@mail.com'});
      await pumpFor(tester);
    }

    Future<void> submitCode(WidgetTester tester, String code) async {
      Get.find<EmailVerificationController>().codeController.text = code;
      await pumpFor(tester);
      if (Get.currentRoute == GetRoutes.verifyEmail) {
        await tester.ensureVisible(find.text('Verificar correo'));
        await tester.tap(find.text('Verificar correo'));
        await pumpFor(tester);
      }
    }

    testWidgets('código inválido: muestra el motivo y no sale',
        (tester) async {
      await openVerification(tester);
      await submitCode(tester, '000000');

      expect(find.text('El código es incorrecto o ya venció'), findsOneWidget);
      expect(Get.currentRoute, GetRoutes.verifyEmail);
      await expireSnackbarOnCodeScreen(tester);
    });

    testWidgets('código correcto: entra a la home con la sesión del registro',
        (tester) async {
      await session.start(fakeJwt({
        'id': 'o2',
        'roles': ['Owner'],
        'exp': epochSeconds(DateTime.now().add(const Duration(days: 1))),
      }));
      session.clear();
      await openVerification(tester);
      await submitCode(tester, FakeAuthRepository.validCode);

      expect(repo.verifications.last, ('olga@mail.com', '123456'));
      expect(Get.currentRoute, GetRoutes.home);
      expect(session.isLoggedIn, isTrue);
      expect(store.token, isNotNull, reason: 'ya no se borra el token');
      await expireSnackbar(tester);
    });
  });

  group('Recuperar contraseña', () {
    testWidgets('pide el código, cambia la contraseña y vuelve al login',
        (tester) async {
      await pumpApp(tester, GetRoutes.login);
      await tapText(tester, '¿Olvidaste tu contraseña?');
      await tester.enterText(field('Correo electrónico'), 'olga@mail.com');
      await tapAndPump(tester, 'Enviar código');

      expect(repo.resetRequests, ['olga@mail.com']);
      expect(Get.currentRoute, GetRoutes.resetPassword);

      final controller = Get.find<ResetPasswordController>();
      controller.codeController.text = '000000';
      await tester.enterText(field('Nueva contraseña'), 'Nueva123!');
      await tester.enterText(field('Confirmar contraseña'), 'Nueva123!');
      await tester.ensureVisible(find.text('Cambiar contraseña'));
      await tester.tap(find.text('Cambiar contraseña'));
      await pumpFor(tester);

      expect(find.text('El código de recuperación no es válido'),
          findsOneWidget);
      expect(Get.currentRoute, GetRoutes.resetPassword);

      controller.codeController.text = FakeAuthRepository.validCode;
      await tester.tap(find.text('Cambiar contraseña'));
      await pumpFor(tester);

      expect(repo.resets.last, ('olga@mail.com', '123456', 'Nueva123!'));
      expect(Get.currentRoute, GetRoutes.login);
      expect(find.text('Contraseña actualizada'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('las contraseñas deben coincidir', (tester) async {
      await pumpApp(tester, GetRoutes.login);
      Get.toNamed(GetRoutes.resetPassword,
          arguments: {'email': 'olga@mail.com'});
      await pumpFor(tester);

      Get.find<ResetPasswordController>().codeController.text = '123456';
      await tester.enterText(field('Nueva contraseña'), 'Nueva123!');
      await tester.enterText(field('Confirmar contraseña'), 'Otra123!');
      await tester.ensureVisible(find.text('Cambiar contraseña'));
      await tester.tap(find.text('Cambiar contraseña'));
      await pumpFor(tester);

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(repo.resets, isEmpty);
    });
  });
}
