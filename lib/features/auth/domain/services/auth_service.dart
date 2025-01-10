// lib/features/auth/domain/services/auth_service.dart
import 'package:get/get.dart';
import '../../../../shared/local_storage/local_storage.dart';

class AuthService extends GetxService {
  final LocalStorage _localStorage;

  AuthService({required LocalStorage localStorage})
      : _localStorage = localStorage;

  Future<void> signOut() async {
    try {
      await _localStorage.clearSession();
    } catch (e) {
      throw Exception('Error durante el cierre de sesión: $e');
    }
  }
}
