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
      if (token != null && token.isNotEmpty) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          );

          // Validar y asignar datos del usuario de forma segura
          userName.value = _getSafeString(payload['name'], 'Usuario');
          userEmail.value = _getSafeString(payload['email'], 'correo@ejemplo.com');
          userInitial.value = _getInitial(payload['name']);
          _loadUserRoles(payload['roles']);
          
          print('Usuario cargado: ${userName.value} (${userEmail.value})');
          print('Roles del usuario: ${userRoles.join(', ')}');
        } else {
          print('Token JWT inválido: estructura incorrecta');
          _setDefaultValues();
        }
      } else {
        print('No hay token disponible');
        _setDefaultValues();
      }
    } catch (e) {
      print('Error al cargar información del usuario: $e');
      _setDefaultValues();
    }
  }

  String _getSafeString(dynamic value, String defaultValue) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return defaultValue;
  }

  String _getInitial(dynamic name) {
    if (name is String && name.isNotEmpty) {
      return name.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  void _loadUserRoles(dynamic roles) {
    userRoles.clear();
    if (roles != null) {
      if (roles is List) {
        userRoles.assignAll(List<String>.from(roles));
      } else if (roles is String && roles.isNotEmpty) {
        userRoles.add(roles);
      }
    }
  }

  void _setDefaultValues() {
    userName.value = 'Usuario';
    userEmail.value = 'correo@ejemplo.com';
    userInitial.value = 'U';
    userRoles.clear();
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

  // Método para verificar si el usuario es Owner
  bool isOwner() {
    return userRoles.contains('Owner');
  }

  // Método para verificar si el usuario es Employee (incluye Owner que puede tener ambos roles)
  bool isEmployee() {
    return userRoles.contains('Employee');
  }

  // Método para obtener la ruta de estadísticas según el rol
  String getStatisticsRoute() {
    return isOnlyEmployee() ? '/employee-statistics' : '/statistics';
  }

  // Método para recargar información del usuario (útil después de cambios de rol)
  Future<void> refreshUserInfo() async {
    print('🔄 Recargando información del usuario...');
    await loadUserInfo();
    print('✅ Información del usuario recargada: ${userName.value} - ${userEmail.value} - Roles: ${userRoles}');
  }

  // Método para limpiar información del usuario (útil para logout)
  void clearUserInfo() {
    print('🧹 Limpiando información del usuario...');
    _setDefaultValues();
    print('✅ Información del usuario limpiada');
  }
}
