import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:login_signup/features/auth/data/models/user_model.dart';
import 'package:login_signup/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:login_signup/features/auth/domain/entities/register_owner_input.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';
import 'auth_models_test.dart' show backendAuth, backendUser;
import 'auth_repository_test.dart' show FakeGoogle, agendityJwt, rightOf;

/// Zona horaria en auth (D-15, 6.04): el alta envía la del dispositivo y la
/// sesión toma la del negocio de `GET /auth/me`.
void main() {
  late FakeHttpClientAdapter adapter;
  late MemoryTokenStore tokens;
  late AuthRepositoryImpl repository;
  String? deviceZone;

  const owner = RegisterOwnerInput(
    name: 'Ana',
    lastname: 'Pérez',
    email: 'ana@example.com',
    phone: '3001234567',
    password: 'Clave#2026',
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    deviceZone = 'America/Caracas';
    tokens = MemoryTokenStore();
    adapter = FakeHttpClientAdapter((request) => request.path == '/auth/me'
        ? jsonBody(200, {...backendUser(), 'timezone': 'America/Caracas'})
        : jsonBody(201, backendAuth(agendityJwt)));
    final dio = buildApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: tokens,
      httpClientAdapter: adapter,
      retryDelay: (_) => Duration.zero,
      enableLogs: false,
    );
    final remote = AuthRemoteDataSourceImpl(dio);
    // Como `AuthDependencies`: la sesión lee la zona de /auth/me.
    final session = SessionService(
      tokenStore: tokens,
      repository: SessionRepository(tokens),
      timeZoneStore: MemoryTimeZoneStore(),
      loadTimeZone: () async => (await remote.me()).timeZone,
    );
    repository = AuthRepositoryImpl(
      remote: remote,
      google: FakeGoogle(),
      session: session,
      localStorage: LocalStorage(const FlutterSecureStorage(), tokenStore: tokens),
      deviceTimeZone: () async => deviceZone,
    );
  });

  tearDown(BusinessTimeZone.reset);

  Map<String, dynamic> bodyOf(String path) => adapter.requests
      .singleWhere((r) => r.path == path)
      .data as Map<String, dynamic>;

  test('el alta envía la zona del dispositivo', () async {
    rightOf(await repository.registerOwner(owner));
    expect(bodyOf('/auth/register/owner')['timezone'], 'America/Caracas');
  });

  test('una zona elegida en el formulario gana a la del dispositivo',
      () async {
    rightOf(await repository
        .registerOwner(owner.withTimeZone('America/Bogota').normalized()));
    expect(bodyOf('/auth/register/owner')['timezone'], 'America/Bogota');
  });

  test('sin zona del dispositivo (o si falla) no se envía: el backend usa '
      'la suya', () async {
    deviceZone = null;
    rightOf(await repository.registerOwner(owner));
    expect(bodyOf('/auth/register/owner').containsKey('timezone'), false);

    adapter.requests.clear();
    repository = AuthRepositoryImpl(
      remote: AuthRemoteDataSourceImpl(buildApiClient(
          baseUrl: 'http://api.test/api',
          tokenStore: tokens,
          httpClientAdapter: adapter,
          enableLogs: false)),
      google: FakeGoogle(),
      session: SessionService(
          tokenStore: tokens, repository: SessionRepository(tokens)),
      localStorage: LocalStorage(const FlutterSecureStorage(), tokenStore: tokens),
      deviceTimeZone: () async => throw StateError('sin plugin'),
    );
    rightOf(await repository.registerOwner(owner));
    expect(bodyOf('/auth/register/owner').containsKey('timezone'), false);
  });

  test('Google envía la zona del dispositivo (solo cuenta en un alta nueva)',
      () async {
    rightOf(await repository.signInWithGoogle());
    expect(bodyOf('/auth/google'),
        {'token': 'google-id-token', 'timezone': 'America/Caracas'});
  });

  test('tras el login, la sesión queda en la zona del negocio (/auth/me)',
      () async {
    deviceZone = 'America/Bogota';
    rightOf(await repository.login(email: 'ana@example.com', password: 'x'));
    final me = adapter.requests.singleWhere((r) => r.path == '/auth/me');
    expect(me.headers['Authorization'], 'Bearer $agendityJwt');
    expect(BusinessTimeZone.current, 'America/Caracas');
  });

  test('UserModel lee `timezone` de /auth/me', () {
    final user = UserModel.fromJson(
        {...backendUser(), 'timezone': 'America/Caracas'}).toEntity();
    expect(user.timeZone, 'America/Caracas');
    expect(UserModel.fromJson(backendUser()).toEntity().timeZone, isNull);
  });

  test('RegisterOwnerInput.normalized: zona vacía = sin zona', () {
    expect(owner.withTimeZone('  ').normalized().timeZone, isNull);
    expect(owner.withTimeZone(' America/Bogota ').normalized().timeZone,
        'America/Bogota');
  });
}
