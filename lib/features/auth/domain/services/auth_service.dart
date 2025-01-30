// lib/features/auth/domain/services/auth_service.dart
import 'package:get/get.dart';
import '../../../../shared/local_storage/local_storage.dart';

class AuthService extends GetxService {
  final LocalStorage _localStorage;
  final RxBool isAuthenticated = false.obs;

  AuthService({required LocalStorage localStorage})
      : _localStorage = localStorage;

  Future<bool> init() async {
    final token = await _localStorage.getToken();
    isAuthenticated.value = token != null;
    return true;
  }

  Future<void> signOut() async {
    try {
      print('AuthService: Iniciando proceso de signOut...'); // Debug
      await _localStorage.deleteToken();
      print('AuthService: Token eliminado'); // Debug
      await _localStorage.clearAllData();
      print('AuthService: Todos los datos limpiados'); // Debug
      isAuthenticated.value = false;
    } catch (e) {
      print('AuthService: Error en signOut: $e'); // Debug
      throw Exception('Error al cerrar sesión: ${e.toString()}');
    }
  }

  Future<bool> checkAuth() async {
    final token = await _localStorage.getToken();
    print('AuthService: Token actual: $token'); // Debug
    isAuthenticated.value = token != null;
    return isAuthenticated.value;
  }

  // Método para actualizar el estado de autenticación después del login
  void setAuthenticated(bool value) {
    isAuthenticated.value = value;
  }

  // Método para obtener el token actual
  Future<String?> getToken() async {
    return await _localStorage.getToken();
  }
}
