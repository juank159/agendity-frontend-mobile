import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:login_signup/features/auth/data/datasources/google_auth_datasource.dart';
import 'package:login_signup/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:login_signup/features/auth/domain/entities/register_owner_input.dart';
import 'package:login_signup/features/auth/domain/failures/auth_failures.dart';
import 'package:login_signup/features/auth/domain/usecases/auth_rules.dart';
import 'package:login_signup/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/login_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/logout_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/register_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/request_verification_code_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/verify_email_usecase.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/jwt_helper.dart';
import '../../core/session/memory_token_store.dart';
import 'auth_models_test.dart' show backendAuth, backendUser;

Failure? leftOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => null);

T rightOf<T>(Either<Failure, T> result) =>
    result.getOrElse(() => throw StateError('Left: ${leftOf(result)}'));

ResponseBody errorBody(int status, String code, String message) =>
    jsonBody(status, {'statusCode': status, 'code': code, 'message': message});

/// SDK de Google falso: devuelve [idToken] (`null` = cancelado) o lanza.
class FakeGoogle implements GoogleAuthDataSource {
  String? idToken = 'google-id-token';
  Error? error;
  int signOuts = 0;

  @override
  Future<String?> obtainIdToken() async {
    if (error != null) throw error!;
    return idToken;
  }

  @override
  Future<void> signOut() async => signOuts++;
}

final agendityJwt = fakeJwt({
  'id': 'own-1',
  'name': 'Ana',
  'email': 'ana@example.com',
  'roles': ['Owner'],
  'tenant_id': 'own-1',
  'exp': epochSeconds(DateTime.now().add(const Duration(days: 1))),
});

const newOwner = RegisterOwnerInput(
  name: ' Ana ',
  lastname: 'Pérez',
  email: ' ana@example.com ',
  phone: '3001234567',
  password: 'Clave#2026',
);

void main() {
  late FakeHttpClientAdapter adapter;
  late MemoryTokenStore tokens;
  late FakeGoogle google;
  late AuthRepositoryImpl repository;
  late int expiredSessions;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'theme': 'dark'});
    expiredSessions = 0;
    adapter = FakeHttpClientAdapter((_) => jsonBody(200, {}));
    tokens = MemoryTokenStore();
    google = FakeGoogle();
    final dio = buildApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: tokens,
      onSessionExpired: (_) => expiredSessions++,
      httpClientAdapter: adapter,
      retryDelay: (_) => Duration.zero,
      enableLogs: false,
    );
    repository = AuthRepositoryImpl(
      remote: AuthRemoteDataSourceImpl(dio),
      google: google,
      session: SessionService(
          tokenStore: tokens, repository: SessionRepository(tokens)),
      localStorage:
          LocalStorage(const FlutterSecureStorage(), tokenStore: tokens),
    );
  });

  group('login', () {
    test('correcto: POST público, guarda el JWT y devuelve el usuario',
        () async {
      tokens.token = 'token.viejo.x';
      adapter.handler = (_) => jsonBody(200, backendAuth(agendityJwt));
      final user = rightOf(await LoginUseCase(repository)(const LoginParams(
          email: ' ana@example.com ', password: 'Clave#2026')));

      expect(user.id, 'own-1');
      expect(user.roles, ['Owner']);
      expect(tokens.token, agendityJwt);
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/auth/login');
      expect(
          request.data, {'email': 'ana@example.com', 'password': 'Clave#2026'});
      expect(request.headers.containsKey('Authorization'), false,
          reason: 'ruta pública: sin token');
    });

    test('credenciales inválidas (401) → InvalidCredentialsFailure sin sesión',
        () async {
      adapter.handler =
          (_) => errorBody(401, 'UNAUTHORIZED', 'Credenciales inválidas');
      final failure = leftOf(
          await repository.login(email: 'ana@example.com', password: 'mala'));
      expect(failure, isA<InvalidCredentialsFailure>());
      expect(failure!.message, 'Credenciales inválidas');
      expect(tokens.token, isNull);
      expect(expiredSessions, 0,
          reason: 'el 401 del login no es sesión vencida');
    });

    test('ACCOUNT_INACTIVE (403) → AccountInactiveFailure con el motivo',
        () async {
      adapter.handler = (_) => errorBody(403, 'ACCOUNT_INACTIVE',
          'Tu cuenta aún no está activa: verifica tu email');
      final failure = leftOf(await repository.login(
          email: 'ana@example.com', password: 'Clave#2026'));
      expect(failure, isA<AccountInactiveFailure>());
      expect(failure, isA<ForbiddenFailure>());
      expect(failure!.code, ApiErrorCode.accountInactive);
      expect(
          failure.message, 'Tu cuenta aún no está activa: verifica tu email');
      expect(tokens.token, isNull);
    });

    test('429 TOO_MANY_REQUESTS → TooManyRequestsFailure', () async {
      adapter.handler =
          (_) => errorBody(429, 'TOO_MANY_REQUESTS', 'Demasiadas solicitudes');
      expect(
          leftOf(
              await repository.login(email: 'ana@example.com', password: 'x')),
          isA<TooManyRequestsFailure>());
    });

    test('sin red → NetworkFailure', () async {
      adapter.handler = connectionError;
      expect(
          leftOf(
              await repository.login(email: 'ana@example.com', password: 'x')),
          isA<NetworkFailure>());
      expect(tokens.token, isNull);
    });

    test('respuesta sin token o con un token que no es JWT → sin sesión',
        () async {
      adapter.handler = (_) => jsonBody(200, {'user': backendUser()});
      expect(
          leftOf(
              await repository.login(email: 'ana@example.com', password: 'x')),
          isA<ServerFailure>());
      adapter.handler = (_) => jsonBody(200, backendAuth('no-es-un-jwt'));
      expect(
          leftOf(
              await repository.login(email: 'ana@example.com', password: 'x')),
          isA<ServerFailure>());
      expect(tokens.token, isNull);
    });

    test('email inválido → failure local sin red', () async {
      final failure = leftOf(await LoginUseCase(repository)(
          const LoginParams(email: 'ana', password: 'x')));
      expect(failure, isA<InvalidAuthDataFailure>());
      expect(failure!.message, AuthRules.invalidEmail);
      expect(adapter.requests, isEmpty);
    });
  });

  group('registro', () {
    test('POST /auth/register/owner con los datos limpios e inicia sesión',
        () async {
      adapter.handler = (_) => jsonBody(201, backendAuth(agendityJwt));
      final user = rightOf(await RegisterUseCase(repository)(newOwner));
      expect(user.email, 'ana@example.com');
      expect(tokens.token, agendityJwt);
      final request = adapter.requests.single;
      expect(request.uri.path, '/api/auth/register/owner');
      expect(request.data, {
        'name': 'Ana',
        'lastname': 'Pérez',
        'email': 'ana@example.com',
        'phone': '3001234567',
        'password': 'Clave#2026',
      });
      expect(request.headers.containsKey('Authorization'), false);
    });

    test('email repetido (409 DUPLICATE_EMAIL) → DuplicateEmailFailure',
        () async {
      adapter.handler = (_) => errorBody(409, 'DUPLICATE_EMAIL',
          'Ya existe un usuario con el email: ana@example.com');
      final failure = leftOf(await RegisterUseCase(repository)(newOwner));
      expect(failure, isA<DuplicateEmailFailure>());
      expect(failure!.message,
          'Ya existe un usuario con el email: ana@example.com');
      expect(tokens.token, isNull);
    });
  });

  group('Google', () {
    test(
        'correcto: envía el ID token y guarda el JWT de Agendity, no el de Google',
        () async {
      adapter.handler = (_) => jsonBody(
          200,
          backendAuth(agendityJwt,
              user: {...backendUser(phone: null), 'is_email_verified': true}));
      final user = rightOf(await GoogleSignInUseCase(repository)(NoParams()));

      expect(user.id, 'own-1',
          reason: 'el usuario de la respuesta, no el de Google');
      expect(user.phone, isNull);
      expect(tokens.token, agendityJwt);
      final request = adapter.requests.single;
      expect(request.uri.path, '/api/auth/google');
      expect(request.data, {'token': 'google-id-token'});
      expect(request.headers.containsKey('Authorization'), false);
    });

    test('rechazado por el backend (401) → sin sesión y sin token de Google',
        () async {
      adapter.handler =
          (_) => errorBody(401, 'UNAUTHORIZED', 'Token de Google inválido');
      final failure = leftOf(await repository.signInWithGoogle());
      expect(failure, isA<GoogleSignInRejectedFailure>());
      expect(failure!.message, 'Token de Google inválido');
      expect(tokens.token, isNull);
      expect(expiredSessions, 0);
    });

    test('backend caído → failure y sin sesión (antes seguía con el de Google)',
        () async {
      adapter.handler = connectionError;
      expect(
          leftOf(await repository.signInWithGoogle()), isA<NetworkFailure>());
      expect(tokens.token, isNull);
    });

    test('cuenta sin acceso → AccountInactiveFailure', () async {
      adapter.handler = (_) =>
          errorBody(403, 'ACCOUNT_INACTIVE', 'Esta cuenta fue desactivada');
      expect(leftOf(await repository.signInWithGoogle()),
          isA<AccountInactiveFailure>());
      expect(tokens.token, isNull);
    });

    test('cancelado o sin ID token → sin llamar al backend', () async {
      google.idToken = null;
      expect(leftOf(await repository.signInWithGoogle()),
          isA<GoogleSignInCancelledFailure>());
      google.error = StateError('Google no devolvió un ID token');
      expect(leftOf(await repository.signInWithGoogle()),
          isA<GoogleSignInRejectedFailure>());
      expect(adapter.requests, isEmpty);
      expect(tokens.token, isNull);
    });
  });

  group('códigos', () {
    test('pedir código: solo el email (sin isNewUser), público', () async {
      adapter.handler =
          (_) => jsonBody(201, {'message': 'Código de verificación enviado'});
      expect(
          await RequestVerificationCodeUseCase(repository)(' ana@example.com '),
          const Right(unit));
      final request = adapter.requests.single;
      expect(request.uri.path, '/api/auth/verify/request-code');
      expect(request.data, {'email': 'ana@example.com'});
      expect(request.headers.containsKey('Authorization'), false);
    });

    test('pedir código de un email desconocido (404) → NotFoundFailure',
        () async {
      adapter.handler =
          (_) => errorBody(404, 'NOT_FOUND', 'Usuario no encontrado');
      expect(leftOf(await repository.requestVerificationCode('x@example.com')),
          isA<NotFoundFailure>());
    });

    test('verificar email', () async {
      adapter.handler = (_) => jsonBody(201,
          {'message': 'Email verificado correctamente', 'is_verified': true});
      expect(
          await VerifyEmailUseCase(repository)(const VerifyEmailParams(
              email: 'ana@example.com', code: '123456')),
          const Right(unit));
      expect(adapter.requests.single.uri.path, '/api/auth/verify/email');
      expect(adapter.requests.single.data,
          {'email': 'ana@example.com', 'code': '123456'});
    });

    test(
        'código inválido (400 INVALID_VERIFICATION_CODE) → failure con el motivo',
        () async {
      adapter.handler = (_) => errorBody(400, 'INVALID_VERIFICATION_CODE',
          'El código de verificación ha expirado');
      final failure = leftOf(await repository.verifyEmail(
          email: 'ana@example.com', code: '000000'));
      expect(failure, isA<InvalidVerificationCodeFailure>());
      expect(failure!.message, 'El código de verificación ha expirado');

      adapter.handler = (_) => errorBody(
          400, 'INVALID_VERIFICATION_CODE', 'Código de recuperación inválido');
      final reset = leftOf(await ResetPasswordUseCase(repository)(
          const ResetPasswordParams(
              email: 'ana@example.com',
              code: '000000',
              newPassword: 'N#2026ab')));
      expect(reset, isA<InvalidVerificationCodeFailure>());
      expect(reset!.message, 'Código de recuperación inválido');
    });

    test('olvidé mi contraseña y restablecerla', () async {
      adapter.handler = (_) => jsonBody(201, {'message': 'ok'});
      expect(await RequestPasswordResetUseCase(repository)('ana@example.com'),
          const Right(unit));
      expect(
          await ResetPasswordUseCase(repository)(const ResetPasswordParams(
              email: 'ana@example.com',
              code: '123456',
              newPassword: 'N#2026ab')),
          const Right(unit));
      expect(adapter.requests.map((r) => r.uri.path),
          ['/api/auth/forgot-password', '/api/auth/reset-password']);
      expect(adapter.requests.last.data, {
        'email': 'ana@example.com',
        'code': '123456',
        'newPassword': 'N#2026ab',
      });
    });

    test('código vacío o email inválido → failure local sin red', () async {
      expect(
          leftOf(await VerifyEmailUseCase(repository)(
              const VerifyEmailParams(email: 'ana@example.com', code: ' '))),
          isA<InvalidAuthDataFailure>());
      expect(leftOf(await RequestPasswordResetUseCase(repository)('ana')),
          isA<InvalidAuthDataFailure>());
      expect(adapter.requests, isEmpty);
    });
  });

  test('logout: borra la sesión, los datos locales y la sesión de Google',
      () async {
    tokens.token = agendityJwt;
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'theme'), 'dark');

    expect(await LogoutUseCase(repository)(NoParams()), const Right(unit));
    expect(tokens.token, isNull);
    expect(await storage.read(key: 'theme'), isNull);
    expect(google.signOuts, 1);
    expect(adapter.requests, isEmpty);
  });
}
