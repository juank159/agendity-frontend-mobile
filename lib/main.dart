import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/core/config/env_config.dart';

import 'package:login_signup/core/di/init_dependencies.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/firebase_options.dart';
import 'package:login_signup/shared/controllers/theme_controller.dart';
import 'package:login_signup/core/utils/app_logger.dart';

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
    _registerFontLicense();

    AppLogger.debug('Rutas registradas: ${GetRoutes.routes.length}');

    runApp(const MyApp());
  } catch (e) {
    AppLogger.error('Error inicializando la aplicación', e);
    rethrow;
  }
}

/// Licencia OFL de Plus Jakarta Sans (assets/fonts) en "Licencias".
void _registerFontLicense() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Plus Jakarta Sans'], text);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<ThemeController>(
      builder: (controller) {
        return GetMaterialApp(
          title: 'Agendity',
          debugShowCheckedModeBanner: false,
          initialRoute: GetRoutes.splas,
          getPages: GetRoutes.routes,
          unknownRoute: GetRoutes.unknownRoute,

          // Temas por paleta y modo (D-22; tokens en core/config). El alto
          // contraste llega como darkTheme con ThemeMode.dark.
          theme: controller.theme,
          darkTheme: controller.darkTheme,
          themeMode: controller.themeMode,

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

          // D-23: horas en 12 h con a. m./p. m. en toda la app, sea cual sea
          // el ajuste del dispositivo. Las horas visibles salen de
          // `formatClock` (core/utils/formatters.dart) y el selector es
          // `AppTimePicker` (ruedas de 12 h); esto cubre lo que aún dependa
          // del ajuste (p. ej. widgets de Material o de paquetes).
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
            AppLogger.debug('App inicializada correctamente');
          },

          // Configuración de navegación
          defaultTransition: Transition.fade,
          defaultGlobalState: true,
        );
      },
    );
  }
}
