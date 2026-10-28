import 'package:dio/dio.dart';
import 'package:login_signup/core/network/interceptors/auth_interceptor.dart';
import 'package:login_signup/features/auth/data/models/user_model.dart';
import 'package:login_signup/features/auth/domain/entities/register_owner_input.dart';

/// `/auth/*` sobre el Dio `api` (ARQUITECTURA §4): las públicas van con
/// `AuthInterceptor.publicKey` (sin token; su 401 no cierra sesión); `me` va
/// con el token de la sesión. Sin try/catch: los errores los traduce
/// `safeCall` por `code`.
abstract class AuthRemoteDataSource {
  /// `POST /auth/login` → `{user, token}`.
  Future<AuthResponseModel> login(String email, String password);

  /// `POST /auth/register/owner` → `{user, token}`.
  Future<AuthResponseModel> registerOwner(RegisterOwnerInput input);

  /// `POST /auth/google` con el ID token de Google → `{user, token}`.
  Future<AuthResponseModel> googleLogin(String idToken);

  /// `POST /auth/verify/request-code`.
  Future<void> requestVerificationCode(String email);

  /// `POST /auth/verify/email`.
  Future<void> verifyEmail(String email, String code);

  /// `POST /auth/forgot-password`.
  Future<void> requestPasswordReset(String email);

  /// `POST /auth/reset-password`.
  Future<void> resetPassword(String email, String code, String newPassword);

  /// `GET /auth/me` (con sesión, 2.35): el usuario de la sesión sin secretos.
  Future<UserModel> me();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  static final _public = Options(extra: {AuthInterceptor.publicKey: true});

  Future<AuthResponseModel> _auth(String path, Object data) async {
    final response = await _dio.post<Map<String, dynamic>>(path,
        data: data, options: _public);
    return AuthResponseModel.fromJson(response.data);
  }

  Future<void> _post(String path, Object data) =>
      _dio.post<void>(path, data: data, options: _public);

  @override
  Future<AuthResponseModel> login(String email, String password) =>
      _auth('/auth/login', {'email': email, 'password': password});

  @override
  Future<AuthResponseModel> registerOwner(RegisterOwnerInput input) =>
      _auth('/auth/register/owner', {
        'name': input.name,
        'lastname': input.lastname,
        'email': input.email,
        'phone': input.phone,
        'password': input.password,
      });

  @override
  Future<AuthResponseModel> googleLogin(String idToken) =>
      _auth('/auth/google', {'token': idToken});

  @override
  Future<void> requestVerificationCode(String email) =>
      _post('/auth/verify/request-code', {'email': email});

  @override
  Future<void> verifyEmail(String email, String code) =>
      _post('/auth/verify/email', {'email': email, 'code': code});

  @override
  Future<void> requestPasswordReset(String email) =>
      _post('/auth/forgot-password', {'email': email});

  @override
  Future<void> resetPassword(String email, String code, String newPassword) =>
      _post('/auth/reset-password',
          {'email': email, 'code': code, 'newPassword': newPassword});

  @override
  Future<UserModel> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    return UserModel.fromJson(response.data!);
  }
}
