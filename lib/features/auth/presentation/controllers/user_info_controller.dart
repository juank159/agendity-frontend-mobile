import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class UserInfoController extends GetxController {
  final storage = const FlutterSecureStorage();
  final userName = ''.obs;
  final userEmail = ''.obs;
  final userInitial = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    try {
      final token = await storage.read(key: 'token');
      if (token != null) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          );

          userName.value = payload['name'] ?? 'Usuario';
          userEmail.value = payload['email'] ?? 'correo@ejemplo.com';
          userInitial.value = (payload['name'] as String?)?.isNotEmpty == true
              ? payload['name'].toString().substring(0, 1).toUpperCase()
              : 'U';
        }
      }
    } catch (e) {
      print('Error al cargar información del usuario: $e');
      // Valores por defecto en caso de error
      userName.value = 'Usuario';
      userEmail.value = 'correo@ejemplo.com';
      userInitial.value = 'U';
    }
  }
}
