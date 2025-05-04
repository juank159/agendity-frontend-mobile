import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class UserInfoController extends GetxController {
  final storage = const FlutterSecureStorage();
  final userName = ''.obs;
  final userEmail = ''.obs;
  final userInitial = ''.obs;
  final userRoles = <String>[].obs;

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
          if (payload['roles'] != null) {
            if (payload['roles'] is List) {
              userRoles.assignAll(List<String>.from(payload['roles']));
            } else if (payload['roles'] is String) {
              userRoles.add(payload['roles']);
            }
          }
          print('Roles del usuario: ${userRoles.join(', ')}');
        }
      }
    } catch (e) {
      print('Error al cargar información del usuario: $e');
      // Valores por defecto en caso de error
      userName.value = 'Usuario';
      userEmail.value = 'correo@ejemplo.com';
      userInitial.value = 'U';
      userRoles.clear();
    }
  }

  void printUserRoles() {
    print('Roles del usuario desde UserInfoController: $userRoles');
    print('¿Es solo Employee?: ${isOnlyEmployee()}');
  }

  // Método para verificar si el usuario tiene un rol específico
  bool hasRole(String role) {
    return userRoles.contains(role);
  }

  // Método para verificar si el usuario es solo empleado (tiene rol Employee pero no Owner)
  bool isOnlyEmployee() {
    return userRoles.contains('Employee') && !userRoles.contains('Owner');
  }
}
