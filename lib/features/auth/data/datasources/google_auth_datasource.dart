// lib/features/auth/data/datasources/google_auth_datasource.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:login_signup/core/errors/exceptions.dart';
import 'package:login_signup/features/auth/data/models/user_model.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

abstract class GoogleAuthDataSource {
  Future<(UserModel, String)> signInWithGoogle();
}

class GoogleAuthDataSourceImpl implements GoogleAuthDataSource {
  final Dio dio;
  final LocalStorage localStorage;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  GoogleAuthDataSourceImpl({
    required this.dio,
    required this.localStorage,
  });

  @override
  Future<(UserModel, String)> signInWithGoogle() async {
    try {
      // Cerrar cualquier sesión existente para evitar problemas
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();

      // 1. Iniciar el proceso con GoogleSignIn
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Inicio de sesión con Google cancelado');
      }

      // 2. Obtener credenciales de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Crear token usando GoogleSignIn directamente
      final String token =
          googleAuth.idToken ?? googleAuth.accessToken ?? 'temp_token';
      await localStorage.saveToken(token);

      // 4. Crear modelo de usuario con la información obtenida
      String name = 'Usuario';
      String lastname = '';

      if (googleUser.displayName != null &&
          googleUser.displayName!.isNotEmpty) {
        final nameParts = googleUser.displayName!.split(' ');
        name = nameParts.first;
        lastname = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      }

      final UserModel userModel = UserModel(
        id: googleUser.id,
        name: name,
        lastname: lastname,
        email: googleUser.email,
        phone: '',
        image: googleUser.photoUrl,
        roles: ["User"],
      );

      // 5. Opcional: Enviar información al backend si es necesario
      try {
        final response = await dio.post(
          '/auth/google',
          data: {
            'token': token,
            'email': googleUser.email,
            'name': name,
            'lastname': lastname,
            'photo': googleUser.photoUrl,
          },
        );

        if (response.statusCode == 200 && response.data['token'] != null) {
          final backendToken = response.data['token'] as String;
          await localStorage.saveToken(backendToken);
          return (userModel, backendToken);
        }
      } catch (e) {
        print('Error al comunicarse con el backend: $e');
        // Continuar con el token de Google si falla la comunicación con el backend
      }

      return (userModel, token);
    } catch (e) {
      print('Error en Google Sign In: $e');
      if (e is FirebaseAuthException) {
        throw ServerException(
          message: 'Error en Firebase Auth: ${e.message}',
          statusCode: 500,
        );
      } else if (e is DioException) {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Error en la conexión',
          statusCode: e.response?.statusCode ?? 500,
        );
      }
      throw Exception('Error en la autenticación con Google: ${e.toString()}');
    }
  }
}
