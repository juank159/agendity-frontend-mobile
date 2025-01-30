// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:login_signup/core/config/env_config.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/di/init_dependencies.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/bindings/initial_binding.dart'; // Nuevo import

Future<void> main() async {
  try {
    // Aseguramos que Flutter esté inicializado
    WidgetsFlutterBinding.ensureInitialized();

    // Debug: Imprimir rutas registradas
    debugPrint('Rutas registradas:');
    GetRoutes.routes.forEach((route) {
      debugPrint('Ruta: ${route.name}, Page: ${route.page}');
    });

    // Inicializamos configuración y dependencias
    await _initializeApp();

    // Ejecutamos la app
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error inicializando la aplicación: $e');
    rethrow;
  }
}

Future<void> _initializeApp() async {
  try {
    // Inicializamos y validamos variables de entorno
    await EnvConfig.init();
    EnvConfig.validateEnv();

    // Inicializamos todas las dependencias
    await DependencyInjection.init();
  } catch (e) {
    debugPrint('Error en la inicialización: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Tu App',
      debugShowCheckedModeBanner: false,
      initialRoute: GetRoutes.splas,
      getPages: GetRoutes.routes,
      theme: ThemeConfig.lightTheme,
      initialBinding: InitialBinding(),

      // Manejo global de errores
      onUnknownRoute: (settings) {
        return GetPageRoute(
          page: () => const Scaffold(
            body: Center(
              child: Text('Ruta no encontrada'),
            ),
          ),
        );
      },

      navigatorKey: Get.key,
      onInit: () {
        debugPrint('App inicializada correctamente');
      },
    );
  }
}
