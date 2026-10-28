import 'package:google_sign_in/google_sign_in.dart';

/// Solo el SDK de Google: obtiene el ID token que valida el backend
/// (`POST /auth/google`). Nunca guarda nada: la sesión es el JWT de Agendity.
abstract class GoogleAuthDataSource {
  /// ID token de la cuenta elegida; `null` si el usuario canceló. Lanza
  /// `StateError` si Google no dio un ID token.
  Future<String?> obtainIdToken();

  /// Cierra la sesión de Google en el dispositivo (para poder elegir otra
  /// cuenta la próxima vez).
  Future<void> signOut();
}

class GoogleAuthDataSourceImpl implements GoogleAuthDataSource {
  final GoogleSignIn _googleSignIn;

  GoogleAuthDataSourceImpl({GoogleSignIn? googleSignIn})
      : _googleSignIn =
            googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  @override
  Future<String?> obtainIdToken() async {
    // Sin una sesión anterior de Google: siempre se muestra el selector.
    await _googleSignIn.signOut();
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final idToken = (await account.authentication).idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google no devolvió un ID token');
    }
    return idToken;
  }

  @override
  Future<void> signOut() => _googleSignIn.signOut();
}
