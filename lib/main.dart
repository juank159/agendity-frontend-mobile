import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/core/config/env_config.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/di/init_dependencies.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/bindings/initial_binding.dart';
import 'package:login_signup/firebase_options.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Inicializa Firebase con las opciones correctas para la plataforma
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // El resto de tu código de inicialización
    await EnvConfig.init();
    EnvConfig.validateEnv();
    await initializeDateFormatting('es', null);
    await DependencyInjection.init();

    debugPrint('Rutas registradas:');
    GetRoutes.routes.forEach((route) {
      debugPrint('Ruta: ${route.name}, Page: ${route.page}');
    });

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
    // Obtener el tema base
    final baseTheme = ThemeConfig.lightTheme;

    return GetMaterialApp(
      title: 'Tu App',
      debugShowCheckedModeBanner: false,
      initialRoute: GetRoutes.splas,
      getPages: GetRoutes.routes,
      theme: baseTheme.copyWith(
        useMaterial3: true,
        timePickerTheme: TimePickerThemeData(
          backgroundColor: Colors.grey[900],
          hourMinuteShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          dayPeriodShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          dayPeriodBorderSide: const BorderSide(color: Colors.white24),
          dayPeriodTextStyle: const TextStyle(
            fontSize: 16,
          ),
          hourMinuteTextStyle: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
          helpTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      initialBinding: InitialBinding(),

      // Configuración de localización
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
      ],
      locale: const Locale('es'),

      // Builder para forzar formato 12 horas
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: child!,
        );
      },

      // Otras configuraciones
      navigatorKey: Get.key,
      onInit: () {
        debugPrint('App inicializada correctamente');
      },

      // Configuración de navegación
      defaultTransition: Transition.fade,
      defaultGlobalState: true,
    );
  }
}
