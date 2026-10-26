// lib/core/di/modules/services_module.dart
// Sin referencias desde la 4.03: el registro vive en
// features/services/services_dependencies.dart. Pendiente de borrar (D-12).
import 'package:login_signup/features/services/services_dependencies.dart';

class ServicesModule {
  static Future<void> init() async => ServicesDependencies.init();
}
