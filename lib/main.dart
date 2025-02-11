import 'package:flutter/material.dart';

import 'package:get/route_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:login_signup/core/config/env_config.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/di/init_dependencies.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/bindings/initial_binding.dart';

Future<void> _initializeApp() async {
  try {
    await EnvConfig.init();
    EnvConfig.validateEnv();
    await DependencyInjection.init();
  } catch (e) {
    debugPrint('Error en la inicialización: $e');
    rethrow;
  }
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    debugPrint('Rutas registradas:');
    GetRoutes.routes.forEach((route) {
      debugPrint('Ruta: ${route.name}, Page: ${route.page}');
    });

    await _initializeApp();

    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error inicializando la aplicación: $e');
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

      // Configuración de localización
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
      ],
      locale: const Locale('es'),

      // Manejo de rutas desconocidas
      onUnknownRoute: (settings) {
        return GetPageRoute(
          page: () => const Scaffold(
            body: Center(
              child: Text('Ruta no encontrada'),
            ),
          ),
        );
      },

      // Otras configuraciones
      navigatorKey: Get.key,
      onInit: () {
        debugPrint('App inicializada correctamente');
      },

      // Evitar el banner de debug
      debugShowMaterialGrid: false,
      showPerformanceOverlay: false,
      showSemanticsDebugger: false,

      // Configuración de navegación
      defaultTransition: Transition.fade,
      opaqueRoute: Get.isOpaqueRouteDefault,
      popGesture: Get.isPopGestureEnable,
      transitionDuration: Get.defaultTransitionDuration,
      defaultGlobalState: true,
    );
  }
}
