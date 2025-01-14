import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/route_manager.dart';
import 'package:login_signup/core/dependency_injection/dependency_injection.dart';
import 'package:login_signup/core/routes/routes.dart';

Future<void> main() async {
  print('Rutas registradas:');
  GetRoutes.routes.forEach((route) {
    print('Ruta: ${route.name}, Page: ${route.page}');
  });
  WidgetsFlutterBinding.ensureInitialized();

  await DependencyInjection.init();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: GetRoutes.splas,
      getPages: GetRoutes.routes,
    );
  }
}
